//
//  ChatConversationView.swift
//  ParentGuidance
//
//  Created by alex kerss on 23/07/2025.
//

import SwiftUI
import Combine

extension Publishers {
    static var keyboardWillShow: AnyPublisher<CGRect, Never> {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .eraseToAnyPublisher()
    }
}

struct ChatConversationView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var messages: [ChatMessage]
    @Binding var isLoading: Bool
    @State private var inputText: String = ""
    @State private var currentStreamingMessageId: UUID?
    @FocusState private var isInputFocused: Bool
    @StateObject private var voiceRecorderViewModel = VoiceRecorderViewModel()
    @State private var keyboardCancellable: AnyCancellable?
    
    // User language preference for transcription
    @State private var userLanguage: String = "en"
    
    let childName: String
    let apiKey: String
    let onSendMessage: (String) async -> Void
    
    var body: some View {
        VStack(spacing: 0) {
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

                        if isLoading {
                            HStack {
                                ProgressView()
                                    .tint(SemanticColors.accent)
                                Text(String(localized: "chat.message.loading"))
                                    .font(.system(size: 14))
                                    .foregroundColor(SemanticColors.secondaryText)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .id("loading")
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                }
                .onAppear {
                    Task {
                        await loadUserLanguagePreference()
                    }
                    keyboardCancellable = Publishers.keyboardWillShow
                        .sink { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    if let lastMessage = messages.last {
                                        scrollProxy.scrollTo(lastMessage.id, anchor: .top)
                                    }
                                }
                            }
                        }
                }
                .onChange(of: messages.count) { _ in
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                scrollProxy.scrollTo("loading", anchor: .top)
                            }
                        }
                    }
                }
            }

            VStack(spacing: 0) {
                LinearGradient(
                    colors: [SemanticColors.primaryBackground.opacity(0.0), SemanticColors.primaryBackground.opacity(1.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 10)

                ChatInputBar(
                    text: $inputText,
                    onSend: handleSend,
                    onMic: handleMic,
                    isRecording: voiceRecorderViewModel.isRecording,
                    isTranscribing: voiceRecorderViewModel.isTranscribing,
                    isSending: isLoading
                )
                .background(SemanticColors.primaryBackground)
                .padding(.bottom, 8)
            }
        }
        .background(SemanticColors.primaryBackground)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
        .alert(String(localized: "situation.input.recordingError"), isPresented: $voiceRecorderViewModel.showError) {
            Button(String(localized: "common.ok")) {
                voiceRecorderViewModel.clearError()
            }
        } message: {
            Text(voiceRecorderViewModel.errorMessage ?? String(localized: "common.error.generic"))
        }
    }

    private func handleSend() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let messageToSend = trimmedText
        inputText = ""
        isLoading = true

        Task {
            await onSendMessage(messageToSend)
        }
    }

    private func handleMic() {
        if voiceRecorderViewModel.isRecording {
            Task {
                do {
                    let result = try await voiceRecorderViewModel.stopRecordingAndTranscribe(apiKey: apiKey, userLanguage: userLanguage)
                    await MainActor.run {
                        handleTranscriptionComplete(result.transcription)
                    }
                } catch {
                    // Error handled in ViewModel
                }
            }
        } else {
            Task {
                await voiceRecorderViewModel.startRecording()
            }
        }
    }

    private func handleTranscriptionComplete(_ transcription: String) {
        if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            inputText = transcription
        } else {
            inputText += " \(transcription)"
        }
    }
    
    // MARK: - Language Preference Loading
    
    private func loadUserLanguagePreference() async {
        print("🌍 Loading user language preference for transcription")
        
        do {
            // Get current user ID
            guard let userId = SupabaseManager.shared.client.auth.currentUser?.id.uuidString else {
                print("⚠️ No current user, using default language 'en'")
                return
            }
            
            // Get user profile to read preferred language
            let userProfile = try await AuthService.shared.loadUserProfile(userId: userId)
            
            await MainActor.run {
                userLanguage = userProfile.preferredLanguage
                print("✅ User language preference loaded: \(userLanguage)")
            }
        } catch {
            print("❌ Failed to load user language preference: \(error)")
            print("⚠️ Using default language 'en'")
            // userLanguage already defaults to "en"
        }
    }
}
