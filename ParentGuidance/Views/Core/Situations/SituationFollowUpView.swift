import SwiftUI

struct SituationFollowUpView: View {
    @State private var inputText: String = ""
    @State private var isRecording: Bool = false
    @FocusState private var isTextEditorFocused: Bool
    
    let childName: String = "Alex"
    let onAddDetails: () -> Void
    let onContinueAnyway: () -> Void
    let onStartRecording: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Content area
            VStack(spacing: 16) {
                // Situation summary box
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "situation.followup.label"))
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Text(String(localized: "situation.example.text"))
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(ColorPalette.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "situation.followup.button"))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(ColorPalette.white)
                    
                    Text(String(localized: "situation.followup.context"))
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                
                // Text input area with mic button
                ZStack(alignment: .bottomTrailing) {
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
                    
                    // Mic button overlaid at bottom-right
                    MicButton(
                        isRecording: isRecording,
                        action: onStartRecording
                    )
                    .padding(.bottom, 8)
                    .padding(.trailing, 8)
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: onAddDetails) {
                        Text(String(localized: "button.addDetails"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ColorPalette.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(ColorPalette.terracotta)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: onContinueAnyway) {
                        Text(String(localized: "button.continueAnyway"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ColorPalette.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(ColorPalette.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 16)
                
                // Guidance footer
                InputGuidanceFooter()
                    .padding(.top, 8)
                    .padding(.bottom, 140)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .ignoresSafeArea()
    }
}

#Preview {
    SituationFollowUpView(
        onAddDetails: {},
        onContinueAnyway: {},
        onStartRecording: {}
    )
}
