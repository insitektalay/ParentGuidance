import SwiftUI
import Combine

struct SituationInputIdleView: View {
    @State private var inputText: String = ""
    @FocusState private var isTextEditorFocused: Bool
    @StateObject private var voiceRecorderViewModel = VoiceRecorderViewModel()
    
    // Keyboard detection state
    @State private var isKeyboardVisible: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    
    let childName: String
    let apiKey: String
    let onStartRecording: () -> Void
    let onSendMessage: (String) -> Void
    
    // MARK: - Height Calculations
    
    private func availableHeight(for geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        let bottomControlsHeight: CGFloat = 80 // mic + send buttons space
        let bottomPadding: CGFloat = isKeyboardVisible ? 60 : 50 // dynamic tab bar space
        let topPadding: CGFloat = 40 // InputGuidanceFooter + spacing
        let minimumHeight: CGFloat = 120 // minimum usable height
        
        let usedSpace = bottomControlsHeight + bottomPadding + topPadding + keyboardHeight
        let available = screenHeight - usedSpace
        let finalHeight = max(available, minimumHeight)
        
        // Debug logging
        print("📐 Screen height: \(screenHeight)")
        print("📐 Keyboard height: \(keyboardHeight)")
        print("📐 Used space: \(usedSpace) (controls: \(bottomControlsHeight), padding: \(bottomPadding), top: \(topPadding), keyboard: \(keyboardHeight))")
        print("📐 Available height calculated: \(available)")
        print("📐 Final height (with minimum): \(finalHeight)")
        print("📐 Mode: \(isKeyboardVisible ? "keyboard" : "full-screen")")
        
        return finalHeight
    }
    
    var body: some View {
        GeometryReader { geometry in
            let _ = availableHeight(for: geometry) // Calculate height for debugging (not used yet)
            
            VStack(spacing: 0) {
            // Main input area
            VStack(spacing: 8) {
                TextEditor(text: $inputText)
                    .font(.system(size: isKeyboardVisible ? 16 : 18))
                    .foregroundColor(ColorPalette.white)
                    .scrollContentBackground(.hidden)
                    .background(ColorPalette.white.opacity(isKeyboardVisible ? 0.05 : 0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isTextEditorFocused ? ColorPalette.terracotta : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .frame(height: availableHeight(for: geometry))
                    .overlay(
                        Group {
                            if inputText.isEmpty && !isTextEditorFocused {
                                VStack {
                                    HStack {
                                        Text("Describe what's happening with \(childName)...")
                                            .font(.system(size: isKeyboardVisible ? 16 : 18))
                                            .foregroundColor(ColorPalette.white.opacity(isKeyboardVisible ? 0.5 : 0.6))
                                            .padding(.top, 8)
                                            .padding(.leading, 5)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                        }
                    )
                    .focused($isTextEditorFocused)
                    .padding(.horizontal, isKeyboardVisible ? 16 : 20)
                
                InputGuidanceFooter()
                    .padding(.top, 8)
                    .padding(.bottom, 20)
            }
            
            // Input controls
            HStack(spacing: isKeyboardVisible ? 20 : 16) {
                MicButton(
                    isRecording: voiceRecorderViewModel.isRecording || voiceRecorderViewModel.isTranscribing,
                    action: {
                        // Disable button during transcription
                        guard !voiceRecorderViewModel.isTranscribing else { return }
                        Task {
                            await handleMicButtonTap()
                        }
                    }
                )
                
                SendButton(
                    isEnabled: !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    action: {
                        onSendMessage(inputText)
                    }
                )
            }
            .padding(.horizontal, isKeyboardVisible ? 20 : 16)
            .padding(.bottom, isKeyboardVisible ? 60 : 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
        }
        .onAppear {
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        .alert("Recording Error", isPresented: $voiceRecorderViewModel.showError) {
            Button("OK") {
                voiceRecorderViewModel.clearError()
            }
        } message: {
            Text(voiceRecorderViewModel.errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - Voice Recording Methods
    
    private func handleMicButtonTap() async {
        if voiceRecorderViewModel.isRecording {
            // Stop recording and transcribe
            do {
                let result = try await voiceRecorderViewModel.stopRecordingAndTranscribe(apiKey: apiKey)
                await MainActor.run {
                    handleTranscriptionComplete(result.transcription)
                }
            } catch {
                print("❌ Recording failed: \(error)")
            }
        } else {
            // Start recording
            await voiceRecorderViewModel.startRecording()
        }
    }
    
    private func handleTranscriptionComplete(_ transcription: String) {
        // Integrate transcription with text input
        print("🎤 Transcription received: \(transcription)")
        
        // If input is empty, set the transcription as the new text
        if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            inputText = transcription
        } else {
            // If input already has text, append with proper spacing
            let cleanedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            inputText = cleanedInput + " " + transcription
        }
    }
    
    // MARK: - Keyboard Detection Methods
    
    private func setupKeyboardObservers() {
        print("🎹 Setting up keyboard observers")
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            handleKeyboardWillShow(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { notification in
            handleKeyboardWillHide(notification)
        }
    }
    
    private func removeKeyboardObservers() {
        print("🎹 Removing keyboard observers")
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func handleKeyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            print("⚠️ Could not get keyboard frame from notification")
            return
        }
        
        let newKeyboardHeight = keyboardFrame.height
        print("🎹 Keyboard will show - height: \(newKeyboardHeight)")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isKeyboardVisible = true
            keyboardHeight = newKeyboardHeight
        }
        print("🎹 Updated state with animation - isVisible: \(isKeyboardVisible), height: \(keyboardHeight)")
    }
    
    private func handleKeyboardWillHide(_ notification: Notification) {
        print("🎹 Keyboard will hide")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isKeyboardVisible = false
            keyboardHeight = 0
        }
        print("🎹 Updated state with animation - isVisible: \(isKeyboardVisible), height: \(keyboardHeight)")
    }
}

#Preview {
    SituationInputIdleView(
        childName: "Alex",
        apiKey: "test-api-key",
        onStartRecording: {},
        onSendMessage: { _ in }
    )
}
