import SwiftUI

struct SituationInputIdleView: View {
    @State private var inputText: String = ""
    @State private var isRecording: Bool = false
    @FocusState private var isTextEditorFocused: Bool
    
    let childName: String
    let onStartRecording: () -> Void
    let onSendMessage: () -> Void
    
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
                    action: onSendMessage
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 140)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
    }
}

#Preview {
    SituationInputIdleView(
        childName: "Alex",
        onStartRecording: {},
        onSendMessage: {}
    )
}
