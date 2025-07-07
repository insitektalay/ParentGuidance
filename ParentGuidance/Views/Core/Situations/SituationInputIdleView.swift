import SwiftUI

struct SituationInputIdleView: View {
    @State private var inputText: String = ""
    @State private var isRecording: Bool = false
    @FocusState private var isTextEditorFocused: Bool
    
    // Keyboard detection state
    @State private var isKeyboardVisible: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    
    let childName: String
    let onStartRecording: () -> Void
    let onSendMessage: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main input area
            VStack(spacing: 8) {
                TextEditor(text: $inputText)
                    .font(.system(size: 16))
                    .foregroundColor(ColorPalette.white)
                    .scrollContentBackground(.hidden)
                    .background(ColorPalette.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isTextEditorFocused ? ColorPalette.terracotta : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .frame(height: 180)
                    .overlay(
                        Group {
                            if inputText.isEmpty && !isTextEditorFocused {
                                VStack {
                                    HStack {
                                        Text("Describe what's happening with \(childName)...")
                                            .font(.system(size: 16))
                                            .foregroundColor(ColorPalette.white.opacity(0.5))
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
                    .padding(.horizontal, 16)
                
                InputGuidanceFooter()
                    .padding(.top, 8)
            }
            
            Spacer()
            
            // Input controls
            HStack(spacing: 16) {
                MicButton(
                    isRecording: $isRecording,
                    action: onStartRecording
                )
                
                SendButton(
                    isEnabled: !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    action: {
                        onSendMessage(inputText)
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 140)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .onAppear {
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
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
        
        isKeyboardVisible = true
        keyboardHeight = newKeyboardHeight
        print("🎹 Updated state - isVisible: \(isKeyboardVisible), height: \(keyboardHeight)")
    }
    
    private func handleKeyboardWillHide(_ notification: Notification) {
        print("🎹 Keyboard will hide")
        
        isKeyboardVisible = false
        keyboardHeight = 0
        print("🎹 Updated state - isVisible: \(isKeyboardVisible), height: \(keyboardHeight)")
    }
}

#Preview {
    SituationInputIdleView(
        childName: "Alex",
        onStartRecording: {},
        onSendMessage: { _ in }
    )
}
