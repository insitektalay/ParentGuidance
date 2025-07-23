//
//  ChatConversationView.swift
//  ParentGuidance
//
//  Created by alex kerss on 23/07/2025.
//

import SwiftUI
import Combine

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
    
    // Keyboard handling
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages scroll view
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
                    .padding(.bottom, 120) // Add sufficient padding for input bar clearance
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
            
            // Input bar
            ChatInputBar(
                text: $inputText,
                onSend: handleSend,
                onMic: handleMic,
                isRecording: voiceRecorderViewModel.isRecording,
                isTranscribing: voiceRecorderViewModel.isTranscribing,
                isSending: isLoading
            )
            .padding(.bottom, keyboardHeight > 0 ? 0 : 50) // Account for tab bar when keyboard is hidden
        }
        .background(ColorPalette.navy)
        .onAppear {
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        .alert(String(localized: "situation.input.recordingError"), isPresented: $voiceRecorderViewModel.showError) {
            Button(String(localized: "common.ok")) {
                voiceRecorderViewModel.clearError()
            }
        } message: {
            Text(voiceRecorderViewModel.errorMessage ?? String(localized: "common.error.generic"))
        }
    }
    
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
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}
