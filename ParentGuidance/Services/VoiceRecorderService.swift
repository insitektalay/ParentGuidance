//
//  VoiceRecorderService.swift
//  ParentGuidance
//
//  Created by alex kerss on 14/07/2025.
//

import Foundation
import AVFoundation
import Combine

class VoiceRecorderService: NSObject, ObservableObject {
    static let shared = VoiceRecorderService()
    
    // MARK: - Published Properties
    
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var currentRecordingURL: URL?
    
    // MARK: - Private Properties
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var permissionManager = AudioPermissionManager.shared
    
    // MARK: - Delegate
    
    weak var delegate: VoiceRecorderDelegate?
    
    // MARK: - Recording State
    
    enum RecordingState: Equatable {
        case idle
        case preparing
        case recording
        case paused
        case finished
        case error(VoiceRecorderError)
        
        static func == (lhs: RecordingState, rhs: RecordingState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.preparing, .preparing), (.recording, .recording), (.paused, .paused), (.finished, .finished):
                return true
            case (.error, .error):
                return true
            default:
                return false
            }
        }
    }
    
    @Published private(set) var recordingState: RecordingState = .idle
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        print("🎙️ VoiceRecorderService initialized")
    }
    
    // MARK: - Public Recording Methods
    
    func startRecording() async throws -> URL {
        print("🎙️ Starting recording...")
        
        // Notify delegate that recording will start
        await MainActor.run {
            delegate?.voiceRecorderWillStartRecording(self)
        }
        
        // Check permissions first
        let hasPermission = await permissionManager.checkAndRequestPermission()
        guard hasPermission else {
            print("❌ Recording failed: Permission denied")
            await updateRecordingState(.error(.permissionDenied))
            await MainActor.run {
                delegate?.voiceRecorderDidEncounterError(self, error: .permissionDenied)
            }
            throw VoiceRecorderError.permissionDenied
        }
        
        // Check if already recording
        guard recordingState != .recording else {
            print("❌ Recording failed: Already recording")
            let error = VoiceRecorderError.recordingAlreadyInProgress
            await MainActor.run {
                delegate?.voiceRecorderDidEncounterError(self, error: error)
            }
            throw error
        }
        
        await updateRecordingState(.preparing)
        
        do {
            // Configure audio session
            try permissionManager.configureAudioSession()
            print("✅ Audio session configured")
            
            // Create recording URL
            let recordingURL = try createRecordingURL()
            print("📁 Recording URL: \(recordingURL.path)")
            
            // Configure recorder
            let recorder = try createAudioRecorder(url: recordingURL)
            
            // Start recording
            let success = recorder.record()
            guard success else {
                print("❌ Failed to start recording")
                await updateRecordingState(.error(.recordingInitializationFailed(NSError(domain: "RecordingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to start recording"]))))
                throw VoiceRecorderError.recordingInitializationFailed(NSError(domain: "RecordingError", code: -1))
            }
            
            // Update state
            audioRecorder = recorder
            await updateRecordingState(.recording)
            await updateCurrentRecordingURL(recordingURL)
            
            // Start timer
            startRecordingTimer()
            
            // Notify delegate that recording started
            await MainActor.run {
                delegate?.voiceRecorderDidStartRecording(self, fileURL: recordingURL)
            }
            
            print("✅ Recording started successfully")
            return recordingURL
            
        } catch {
            print("❌ Recording start failed: \(error)")
            await updateRecordingState(.error(.recordingInitializationFailed(error)))
            let voiceError = VoiceRecorderError.recordingInitializationFailed(error)
            await MainActor.run {
                delegate?.voiceRecorderDidEncounterError(self, error: voiceError)
            }
            throw voiceError
        }
    }
    
    func stopRecording() async throws -> URL {
        print("🛑 Stopping recording...")
        
        guard recordingState == .recording else {
            print("❌ Stop recording failed: Not currently recording")
            throw VoiceRecorderError.recordingNotStarted
        }
        
        guard let recorder = audioRecorder else {
            print("❌ Stop recording failed: No active recorder")
            throw VoiceRecorderError.recordingNotStarted
        }
        
        guard let recordingURL = currentRecordingURL else {
            print("❌ Stop recording failed: No recording URL")
            throw VoiceRecorderError.fileNotFound
        }
        
        // Stop recording
        recorder.stop()
        stopRecordingTimer()
        
        // Update state
        await updateRecordingState(.finished)
        audioRecorder = nil
        
        // Deactivate audio session
        permissionManager.deactivateAudioSession()
        
        // Validate file exists and has content
        try validateRecordingFile(at: recordingURL)
        
        // Notify delegate that recording stopped
        await MainActor.run {
            delegate?.voiceRecorderDidStopRecording(self, fileURL: recordingURL, duration: recordingDuration)
        }
        
        print("✅ Recording stopped successfully")
        print("📊 Final duration: \(recordingDuration) seconds")
        print("📁 File saved at: \(recordingURL.path)")
        
        return recordingURL
    }
    
    func cancelRecording() async {
        print("❌ Canceling recording...")
        
        guard recordingState == .recording else {
            print("⚠️ Cancel recording: Not currently recording")
            return
        }
        
        // Stop recording
        audioRecorder?.stop()
        stopRecordingTimer()
        
        // Clean up file
        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
            print("🗑️ Temporary recording file deleted")
        }
        
        // Reset state
        await updateRecordingState(.idle)
        await updateCurrentRecordingURL(nil)
        audioRecorder = nil
        
        // Deactivate audio session
        permissionManager.deactivateAudioSession()
        
        // Notify delegate
        await MainActor.run {
            delegate?.voiceRecorderDidCancelRecording(self)
        }
        
        print("✅ Recording canceled")
    }
    
    // MARK: - OpenAI Transcription
    
    func transcribeAudio(fileURL: URL, apiKey: String) async throws -> String {
        print("🎤 Starting transcription for file: \(fileURL.lastPathComponent)")
        
        // Notify delegate that transcription will start
        await MainActor.run {
            delegate?.voiceRecorderWillStartTranscription(self, fileURL: fileURL)
        }
        
        // Validate file exists and size
        try validateRecordingFile(at: fileURL)
        
        // Read audio file data
        let audioData: Data
        do {
            audioData = try Data(contentsOf: fileURL)
            print("📁 Audio file loaded: \(audioData.count) bytes")
        } catch {
            print("❌ Failed to read audio file: \(error)")
            throw VoiceRecorderError.fileNotFound
        }
        
        // Create multipart form-data request
        let boundary = "----Boundary\(UUID().uuidString)"
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build multipart body
        var body = Data()
        
        // Add model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("gpt-4o-transcribe\r\n".data(using: .utf8)!)
        
        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add response_format field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("json\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("📡 Sending transcription request to OpenAI...")
        print("🔗 URL: \(url)")
        print("📦 Body size: \(body.count) bytes")
        
        // Send request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("❌ Network error during transcription: \(error)")
            throw VoiceRecorderError.networkError(error)
        }
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response for transcription")
            throw VoiceRecorderError.invalidResponse
        }
        
        print("📊 Transcription response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            print("❌ Transcription HTTP error: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(responseString)")
            }
            throw VoiceRecorderError.transcriptionFailed(NSError(domain: "OpenAIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]))
        }
        
        // Parse JSON response
        do {
            if let responseString = String(data: data, encoding: .utf8) {
                print("📝 Raw transcription response: \(responseString)")
            }
            
            let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let transcriptionText = jsonResponse?["text"] as? String else {
                print("❌ No transcription text in response")
                throw VoiceRecorderError.noTranscriptionContent
            }
            
            print("✅ Transcription successful")
            print("📝 Transcribed text: \(transcriptionText)")
            
            // Notify delegate of successful transcription
            await MainActor.run {
                delegate?.voiceRecorderDidCompleteTranscription(self, transcription: transcriptionText, fileURL: fileURL)
            }
            
            return transcriptionText
            
        } catch {
            print("❌ Failed to parse transcription response: \(error)")
            let voiceError = VoiceRecorderError.transcriptionFailed(error)
            await MainActor.run {
                delegate?.voiceRecorderDidEncounterError(self, error: voiceError)
            }
            throw voiceError
        }
    }
    
    // MARK: - Complete Recording and Transcription Flow
    
    func recordAndTranscribe(apiKey: String) async throws -> String {
        print("🎙️ Starting complete record and transcribe flow...")
        
        // Start recording
        let recordingURL = try await startRecording()
        
        // Wait for user to stop (this will be handled by UI)
        // For now, this method assumes recording is stopped externally
        
        return recordingURL.path // Placeholder - actual transcription will happen when stopRecording is called
    }
    
    func stopRecordingAndTranscribe(apiKey: String) async throws -> (recordingURL: URL, transcription: String) {
        print("🛑 Stopping recording and starting transcription...")
        
        // Stop recording and get file URL
        let recordingURL = try await stopRecording()
        
        // Transcribe the audio
        let transcription = try await transcribeAudio(fileURL: recordingURL, apiKey: apiKey)
        
        // Notify delegate of complete flow completion
        await MainActor.run {
            delegate?.voiceRecorderDidCompleteRecordingAndTranscription(self, transcription: transcription, fileURL: recordingURL, duration: recordingDuration)
        }
        
        print("✅ Complete flow finished successfully")
        return (recordingURL: recordingURL, transcription: transcription)
    }
    
    // MARK: - File Management
    
    func cleanupRecordingFile(_ url: URL) {
        print("🧹 Cleaning up recording file: \(url.lastPathComponent)")
        
        do {
            try FileManager.default.removeItem(at: url)
            print("✅ Recording file deleted successfully")
        } catch {
            print("⚠️ Failed to delete recording file: \(error)")
        }
    }
    
    func getRecordingFileSize(_ url: URL) throws -> Double {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        let sizeInMB = Double(fileSize) / (1024 * 1024)
        print("📏 Recording file size: \(String(format: "%.2f", sizeInMB))MB")
        return sizeInMB
    }
    
    // MARK: - Private Helper Methods
    
    private func createRecordingURL() throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "recording_\(timestamp).m4a"
        let url = documentsPath.appendingPathComponent(filename)
        
        print("📁 Created recording URL: \(url.lastPathComponent)")
        return url
    }
    
    private func createAudioRecorder(url: URL) throws -> AVAudioRecorder {
        // Configure recording settings for optimal quality and OpenAI compatibility
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        print("🔧 Creating audio recorder with settings:")
        print("   Format: M4A/AAC")
        print("   Sample Rate: 44.1kHz")
        print("   Channels: Mono")
        print("   Quality: High")
        print("   Bit Rate: 128kbps")
        
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.delegate = self
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
        
        print("✅ Audio recorder created and prepared")
        return recorder
    }
    
    private func validateRecordingFile(at url: URL) throws {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ Recording file not found at: \(url.path)")
            throw VoiceRecorderError.fileNotFound
        }
        
        // Check file size
        let sizeInMB = try getRecordingFileSize(url)
        guard sizeInMB <= 25.0 else {
            print("❌ Recording file too large: \(sizeInMB)MB")
            throw VoiceRecorderError.fileTooLarge(sizeInMB: sizeInMB)
        }
        
        // Check minimum size (at least 1KB)
        guard sizeInMB > 0.001 else {
            print("❌ Recording file too small or empty")
            throw VoiceRecorderError.invalidFileFormat
        }
        
        print("✅ Recording file validation passed")
    }
    
    // MARK: - Timer Management
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateRecordingDuration()
            }
        }
        print("⏱️ Recording timer started")
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        print("⏱️ Recording timer stopped")
    }
    
    @MainActor
    private func updateRecordingDuration() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            return
        }
        
        recordingDuration = recorder.currentTime
        
        // Notify delegate of duration update
        delegate?.voiceRecorderDidUpdateRecordingDuration(self, duration: recordingDuration)
    }
    
    // MARK: - State Management
    
    @MainActor
    private func updateRecordingState(_ state: RecordingState) {
        print("🔄 Recording state: \(state)")
        recordingState = state
        
        switch state {
        case .recording:
            isRecording = true
        case .idle, .finished, .error:
            isRecording = false
            recordingDuration = 0
        default:
            break
        }
    }
    
    @MainActor
    private func updateCurrentRecordingURL(_ url: URL?) {
        currentRecordingURL = url
        if url == nil {
            recordingDuration = 0
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension VoiceRecorderService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("🎙️ Audio recorder finished recording successfully: \(flag)")
        
        Task { @MainActor in
            if flag {
                updateRecordingState(.finished)
            } else {
                updateRecordingState(.error(.recordingFailed(NSError(domain: "RecordingError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Recording did not complete successfully"]))))
            }
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("❌ Audio recorder encode error: \(error?.localizedDescription ?? "Unknown error")")
        
        Task { @MainActor in
            if let error = error {
                updateRecordingState(.error(.recordingFailed(error)))
            } else {
                updateRecordingState(.error(.unknown(NSError(domain: "RecordingError", code: -3))))
            }
        }
    }
}
