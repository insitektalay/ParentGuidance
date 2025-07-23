//
//  ChatConversationView.swift
//  ParentGuidance
//
//  Created by alex kerss on 23/07/2025.
//

import SwiftUI
import Combine

struct ChatConversationView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
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
                    .padding(.bottom, 8)
                }
                .onChange(of: messages.count) { _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        if let lastMessage = messages.last {
                            scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        } else if isLoading {
                            scrollProxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isLoading) { _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        if isLoading {
                            scrollProxy.scrollTo("loading", anchor: .bottom)
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
        
        // Add user message
        let userMessage = ChatMessage(text: trimmedText, sender: .user)
        messages.append(userMessage)
        
        // Clear input
        let messageToSend = trimmedText
        inputText = ""
        
        // Start loading
        isLoading = true
        
        // Send message and handle response
        Task {
            await onSendMessage(messageToSend)
            
            // The response will be handled by updateWithGuidanceResponse
            // which should be called from the parent view
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
    
    func updateWithGuidanceResponse(_ guidanceText: String) {
        // Add AI response message
        let aiMessage = ChatMessage(text: guidanceText, sender: .ai)
        messages.append(aiMessage)
        isLoading = false
        currentStreamingMessageId = nil
    }
    
    func updateWithStreamingResponse(_ partialText: String, messageId: UUID) {
        // Update or add streaming message
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            // Update existing message
            messages[index] = ChatMessage(
                text: partialText,
                sender: .ai,
                timestamp: messages[index].timestamp
            )
        } else {
            // Add new message
            let aiMessage = ChatMessage(text: partialText, sender: .ai)
            messages.append(aiMessage)
            currentStreamingMessageId = aiMessage.id
        }
        isLoading = false
    }
    
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
