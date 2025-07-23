//
//  ChatConversationView.swift
//  ParentGuidance
//
//  Created by alex kerss on 23/07/2025.
//

import SwiftUI

struct ChatConversationView: View {
    @Binding var messages: [ChatMessage]
    @Binding var isLoading: Bool
    @State private var inputText: String = ""
    @State private var currentStreamingMessageId: UUID?
    @FocusState private var isInputFocused: Bool
    @StateObject private var voiceRecorderViewModel = VoiceRecorderViewModel()
    
    let childName: String
    let apiKey: String
    let onSendMessage: (String) async -> Void
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages scroll view - takes available space above input bar
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(messages) { message in
                            ChatMessageBubble(
                                message: message,
                                isStreaming: currentStreamingMessageId == message.id
                            )
                            .id(message.id)
                        }
                        
                        // Loading indicator for AI response
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .tint(ColorPalette.terracotta)
                                Text(String(localized: "chat.message.loading"))
                                    .font(.system(size: 14))
                                    .foregroundColor(ColorPalette.white.opacity(0.6))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .id("loading")
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 20) // Space before input bar
                }
                .onChange(of: messages.count) { _ in
                    // Delay scroll slightly to ensure layout is complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            if let lastMessage = messages.last {
                                scrollProxy.scrollTo(lastMessage.id, anchor: .top)
                            }
                        }
                    }
                }
                .onChange(of: isLoading) { newIsLoading in
                    if newIsLoading {
                        // Delay scroll slightly to ensure loading indicator is rendered
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                scrollProxy.scrollTo("loading", anchor: .top)
                            }
                        }
                    }
                }
            }
            
            // Fixed input bar at bottom
            VStack(spacing: 0) {
                // Subtle gradient overlay
                LinearGradient(
                    colors: [ColorPalette.navy.opacity(0.0), ColorPalette.navy.opacity(1.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 10)
                
                // Input bar
                ChatInputBar(
                    text: $inputText,
                    onSend: handleSend,
                    onMic: handleMic,
                    isRecording: voiceRecorderViewModel.isRecording,
                    isTranscribing: voiceRecorderViewModel.isTranscribing,
                    isSending: isLoading
                )
                .background(ColorPalette.navy)
            }
        }
        .background(ColorPalette.navy)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .alert(String(localized: "situation.input.recordingError"), isPresented: $voiceRecorderViewModel.showError) {
            Button(String(localized: "common.ok")) {
                voiceRecorderViewModel.clearError()
            }
        } message: {
            Text(voiceRecorderViewModel.errorMessage ?? String(localized: "common.error.generic"))
        }
    }
    
    // MARK: - Layout Calculations - Simplified with proper keyboard handling
    
    // MARK: - Actions
    
    private func handleSend() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Clear input
        let messageToSend = trimmedText
        inputText = ""
        
        // Start loading (managed by parent)
        isLoading = true
        
        // Send message - parent will handle adding user message and loading state
        Task {
            await onSendMessage(messageToSend)
        }
    }
    
    private func handleMic() {
        if voiceRecorderViewModel.isRecording {
            // Stop recording and transcribe
            Task {
                do {
                    let result = try await voiceRecorderViewModel.stopRecordingAndTranscribe(apiKey: apiKey)
                    await MainActor.run {
                        handleTranscriptionComplete(result.transcription)
                    }
                } catch {
                    // Error handled by view model
                }
            }
        } else {
            // Start recording
            Task {
                await voiceRecorderViewModel.startRecording()
            }
        }
    }
    
    private func handleTranscriptionComplete(_ transcription: String) {
        // Set transcription as input text
        if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            inputText = transcription
        } else {
            inputText = inputText.trimmingCharacters(in: .whitespacesAndNewlines) + " " + transcription
        }
    }
    
    // MARK: - Public Methods for Parent View
    // Note: Messages are now managed by parent view via @Binding
    // Parent view should directly append to the messages array
    
}

