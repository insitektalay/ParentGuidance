//
//  VoiceRecorderViewModel.swift
//  ParentGuidance
//
//  Created by alex kerss on 14/07/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class VoiceRecorderViewModel: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var transcriptionText: String = ""
    @Published var isTranscribing: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false
    
    private let voiceRecorder = VoiceRecorderService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        voiceRecorder.delegate = self
    }
    
    private func setupBindings() {
        // Bind to voice recorder's published properties
        voiceRecorder.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
        
        voiceRecorder.$recordingDuration
            .receive(on: DispatchQueue.main)
            .assign(to: \.recordingDuration, on: self)
            .store(in: &cancellables)
    }
    
    func startRecording() async {
        print("🎙️ ViewModel: Starting recording...")
        clearError()
        
        do {
            let _ = try await voiceRecorder.startRecording()
            print("✅ ViewModel: Recording started successfully")
        } catch {
            print("❌ ViewModel: Recording failed - \(error)")
            await handleError(error)
        }
    }
    
    func stopRecordingAndTranscribe(apiKey: String) async {
        print("🛑 ViewModel: Stopping recording and transcribing...")
        
        do {
            isTranscribing = true
            let result = try await voiceRecorder.stopRecordingAndTranscribe(apiKey: apiKey)
            transcriptionText = result.transcription
            isTranscribing = false
            print("✅ ViewModel: Transcription completed: \(result.transcription)")
        } catch {
            print("❌ ViewModel: Stop and transcribe failed - \(error)")
            isTranscribing = false
            await handleError(error)
        }
    }
    
    func cancelRecording() async {
        print("❌ ViewModel: Canceling recording...")
        await voiceRecorder.cancelRecording()
        clearError()
    }
    
    func clearTranscription() {
        transcriptionText = ""
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    private func handleError(_ error: Error) async {
        let voiceError = error as? VoiceRecorderError ?? VoiceRecorderError.unknown(error)
        errorMessage = voiceError.userFriendlyMessage
        showError = true
        print("❌ ViewModel: Error set - \(errorMessage ?? "nil")")
    }
    
    // MARK: - Formatted Duration
    
    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - UI State Helpers
    
    var canStartRecording: Bool {
        !isRecording && !isTranscribing
    }
    
    var canStopRecording: Bool {
        isRecording && !isTranscribing
    }
    
    var isProcessing: Bool {
        isTranscribing
    }
}

// MARK: - VoiceRecorderDelegate

extension VoiceRecorderViewModel: VoiceRecorderDelegate {
    nonisolated func voiceRecorderWillStartRecording(_ recorder: VoiceRecorderService) {
        print("🎙️ ViewModel Delegate: Will start recording")
    }
    
    nonisolated func voiceRecorderDidStartRecording(_ recorder: VoiceRecorderService, fileURL: URL) {
        print("🎙️ ViewModel Delegate: Did start recording at \(fileURL.lastPathComponent)")
    }
    
    nonisolated func voiceRecorderDidStopRecording(_ recorder: VoiceRecorderService, fileURL: URL, duration: TimeInterval) {
        print("🛑 ViewModel Delegate: Did stop recording - duration: \(duration)s")
    }
    
    nonisolated func voiceRecorderDidCancelRecording(_ recorder: VoiceRecorderService) {
        print("❌ ViewModel Delegate: Did cancel recording")
    }
    
    nonisolated func voiceRecorderWillStartTranscription(_ recorder: VoiceRecorderService, fileURL: URL) {
        print("🎤 ViewModel Delegate: Will start transcription")
    }
    
    nonisolated func voiceRecorderDidCompleteTranscription(_ recorder: VoiceRecorderService, transcription: String, fileURL: URL) {
        print("✅ ViewModel Delegate: Transcription completed")
    }
    
    nonisolated func voiceRecorderDidCompleteRecordingAndTranscription(_ recorder: VoiceRecorderService, transcription: String, fileURL: URL, duration: TimeInterval) {
        print("✅ ViewModel Delegate: Complete flow finished - transcription: \(transcription.prefix(50))...")
    }
    
    nonisolated func voiceRecorderDidEncounterError(_ recorder: VoiceRecorderService, error: VoiceRecorderError) {
        print("❌ ViewModel Delegate: Error encountered - \(error)")
        Task { @MainActor in
            await handleError(error)
        }
    }
    
    nonisolated func voiceRecorderDidUpdateRecordingDuration(_ recorder: VoiceRecorderService, duration: TimeInterval) {
        // This is handled automatically by the @Published binding
    }
}