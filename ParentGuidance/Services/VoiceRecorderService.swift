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
        
        // Check permissions first
        let hasPermission = await permissionManager.checkAndRequestPermission()
        guard hasPermission else {
            print("❌ Recording failed: Permission denied")
            await updateRecordingState(.error(.permissionDenied))
            throw VoiceRecorderError.permissionDenied
        }
        
        // Check if already recording
        guard recordingState != .recording else {
            print("❌ Recording failed: Already recording")
            throw VoiceRecorderError.recordingAlreadyInProgress
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
            
            print("✅ Recording started successfully")
            return recordingURL
            
        } catch {
            print("❌ Recording start failed: \(error)")
            await updateRecordingState(.error(.recordingInitializationFailed(error)))
            throw VoiceRecorderError.recordingInitializationFailed(error)
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
        
        print("✅ Recording canceled")
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
