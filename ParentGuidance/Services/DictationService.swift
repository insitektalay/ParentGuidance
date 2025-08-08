import Foundation
import Speech
import AVFoundation
import SwiftUI

@MainActor
class DictationService: NSObject, ObservableObject {
    static let shared = DictationService()
    
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var error: String?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override init() {
        super.init()
        speechRecognizer?.delegate = self
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.authorizationStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    // MARK: - Recording Control
    
    func startRecording() async throws {
        // Cancel any existing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Check microphone permission
        let microphoneStatus = await AVAudioApplication.requestRecordPermission()
        guard microphoneStatus else {
            throw DictationError.microphoneNotAuthorized
        }
        
        // Check speech recognition authorization
        guard authorizationStatus == .authorized else {
            throw DictationError.speechRecognitionNotAuthorized
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw DictationError.unableToCreateRequest
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw DictationError.recognitionFailed("Failed to configure audio session: \(error.localizedDescription)")
        }
        
        // Create recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self.recognizedText = result.bestTranscription.formattedString
                } else if let error = error {
                    self.error = error.localizedDescription
                    self.stopRecording()
                }
            }
        }
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            throw DictationError.recognitionFailed("Failed to start audio engine: \(error.localizedDescription)")
        }
        
        isRecording = true
        error = nil
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ [DictationService] Failed to deactivate audio session: \(error)")
        }
    }
    
    // MARK: - Text Processing
    
    func clearText() {
        recognizedText = ""
    }
    
    func appendText(_ text: String) {
        if recognizedText.isEmpty {
            recognizedText = text
        } else {
            recognizedText += " " + text
        }
    }
    
    // MARK: - Utility Methods
    
    var canRecord: Bool {
        return authorizationStatus == .authorized && speechRecognizer?.isAvailable == true
    }
    
    var authorizationMessage: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Speech recognition permission not requested"
        case .denied:
            return "Speech recognition access denied. Please enable in Settings."
        case .restricted:
            return "Speech recognition restricted on this device"
        case .authorized:
            return "Speech recognition authorized"
        @unknown default:
            return "Unknown speech recognition status"
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension DictationService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            if !available {
                self.error = "Speech recognition became unavailable"
                self.stopRecording()
            }
        }
    }
}

// MARK: - Error Types

enum DictationError: LocalizedError {
    case speechRecognitionNotAuthorized
    case microphoneNotAuthorized
    case unableToCreateRequest
    case recognitionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .speechRecognitionNotAuthorized:
            return "Speech recognition not authorized. Please enable in Settings."
        case .microphoneNotAuthorized:
            return "Microphone access not authorized. Please enable in Settings."
        case .unableToCreateRequest:
            return "Unable to create speech recognition request"
        case .recognitionFailed(let message):
            return "Speech recognition failed: \(message)"
        }
    }
}

// MARK: - UI Components

struct DictationButton: View {
    @ObservedObject private var dictationService = DictationService.shared
    let onTextReceived: (String) -> Void
    
    var body: some View {
        Button(action: {
            if dictationService.isRecording {
                dictationService.stopRecording()
                if !dictationService.recognizedText.isEmpty {
                    onTextReceived(dictationService.recognizedText)
                    dictationService.clearText()
                }
            } else {
                Task {
                    do {
                        if dictationService.authorizationStatus != .authorized {
                            let authorized = await dictationService.requestAuthorization()
                            guard authorized else { return }
                        }
                        try await dictationService.startRecording()
                    } catch {
                        print("❌ [DictationButton] Failed to start recording: \(error)")
                    }
                }
            }
        }) {
            Image(systemName: dictationService.isRecording ? "stop.circle.fill" : "mic.circle")
                .font(.system(size: 20))
                .foregroundColor(dictationService.isRecording ? .red : SemanticColors.accent)
        }
        .disabled(!dictationService.canRecord && dictationService.authorizationStatus == .authorized)
    }
}

struct DictationStatusView: View {
    @ObservedObject private var dictationService = DictationService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if dictationService.isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(0.8)
                    
                    Text("Recording...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SemanticColors.secondaryText)
                }
            }
            
            if !dictationService.recognizedText.isEmpty {
                Text(dictationService.recognizedText)
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.primaryText)
                    .padding(8)
                    .background(SemanticColors.secondaryBackground)
                    .cornerRadius(6)
            }
            
            if let error = dictationService.error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
    }
}