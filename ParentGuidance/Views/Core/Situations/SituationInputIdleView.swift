import SwiftUI

struct SituationInputIdleView: View {
    @State private var inputText: String = ""
    @State private var isRecording: Bool = false
    
    let childName: String
    let onStartRecording: () -> Void
    let onSendMessage: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with child badge
            HStack {
                ChildBadge(childName: childName)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
            
            // Main input area
            VStack(spacing: 8) {
                TextEditor(text: $inputText)
                    .font(.system(size: 16))
                    .foregroundColor(ColorPalette.white)
                    .scrollContentBackground(.hidden)
                    .background(ColorPalette.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(height: 380)
                    .overlay(
                        Group {
                            if inputText.isEmpty {
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
