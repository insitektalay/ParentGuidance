//
//  SituationVoiceView.swift
//  ParentGuidance
//
//  Created by alex kerss on 14/07/2025.
//

import SwiftUI
import Combine

struct SituationVoiceView: View {
    @ObservedObject var voiceRecorderViewModel: VoiceRecorderViewModel
    let childName: String
    let apiKey: String
    let onTranscriptionComplete: (String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Recording status
            VStack(spacing: 16) {
                if voiceRecorderViewModel.isRecording {
                    // Recording indicator
                    VStack(spacing: 12) {
                        // Animated recording circle
                        ZStack {
                            Circle()
                                .fill(ColorPalette.terracotta.opacity(0.3))
                                .frame(width: 120, height: 120)
                                .scaleEffect(voiceRecorderViewModel.isRecording ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: voiceRecorderViewModel.isRecording)
                            
                            Circle()
                                .fill(ColorPalette.terracotta)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "mic.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                        
                        Text("Recording...")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(voiceRecorderViewModel.formattedDuration)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(ColorPalette.terracotta)
                            .monospaced()
                    }
                } else if voiceRecorderViewModel.isTranscribing {
                    // Transcribing indicator
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: ColorPalette.terracotta))
                        
                        Text("Converting speech to text...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    // Ready to record
                    VStack(spacing: 12) {
                        Circle()
                            .fill(ColorPalette.terracotta.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "mic")
                                    .font(.system(size: 32))
                                    .foregroundColor(ColorPalette.terracotta)
                            )
                        
                        Text("Ready to record")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            // Instructions
            VStack(spacing: 8) {
                if voiceRecorderViewModel.isRecording {
                    Text("Describe what's happening with \(childName)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Tap the microphone when you're done")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                } else if voiceRecorderViewModel.isTranscribing {
                    Text("Processing your recording...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Tap the microphone to start recording")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Controls
            HStack(spacing: 40) {
                // Cancel button
                Button(action: {
                    Task {
                        if voiceRecorderViewModel.isRecording {
                            await voiceRecorderViewModel.cancelRecording()
                        }
                        onCancel()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 56, height: 56)
                        .background(ColorPalette.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(voiceRecorderViewModel.isTranscribing)
                
                // Record/Stop button
                Button(action: {
                    handleRecordButtonTap()
                }) {
                    Image(systemName: voiceRecorderViewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 72, height: 72)
                        .background(voiceRecorderViewModel.isRecording ? ColorPalette.terracotta : ColorPalette.terracotta.opacity(0.8))
                        .clipShape(Circle())
                        .scaleEffect(voiceRecorderViewModel.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: voiceRecorderViewModel.isRecording)
                }
                .disabled(voiceRecorderViewModel.isTranscribing)
            }
            .padding(.bottom, 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .alert("Recording Error", isPresented: $voiceRecorderViewModel.showError) {
            Button("OK") {
                voiceRecorderViewModel.clearError()
            }
        } message: {
            Text(voiceRecorderViewModel.errorMessage ?? "An error occurred")
        }
        .onChange(of: voiceRecorderViewModel.transcriptionText) { [voiceRecorderViewModel] in
            if !voiceRecorderViewModel.transcriptionText.isEmpty {
                onTranscriptionComplete(voiceRecorderViewModel.transcriptionText)
            }
        }
    }
    
    private func handleRecordButtonTap() {
        Task {
            if voiceRecorderViewModel.isRecording {
                // Stop recording and transcribe
                await stopRecordingAndTranscribe()
            } else {
                // Start recording
                await voiceRecorderViewModel.startRecording()
            }
        }
    }
    
    private func stopRecordingAndTranscribe() async {
        await voiceRecorderViewModel.stopRecordingAndTranscribe(apiKey: apiKey)
    }
}

#Preview {
    SituationVoiceView(
        voiceRecorderViewModel: VoiceRecorderViewModel(),
        childName: "Alex",
        apiKey: "test-api-key",
        onTranscriptionComplete: { transcription in
            print("Transcription: \(transcription)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}