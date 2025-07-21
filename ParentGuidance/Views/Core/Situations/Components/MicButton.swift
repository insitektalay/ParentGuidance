import SwiftUI

struct MicButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        
        Button(action: action) {
            ZStack {
                // Static button - no animations at all
                Circle()
                    .fill(isRecording ? Color.red : ColorPalette.terracotta)
                    .frame(width: 56, height: 56)
                
                // Static icon - no animations
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(ColorPalette.white)
                
                // Only show animation effects when actually recording
                if isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .scaleEffect(1.2)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                            value: isRecording
                        )
                }
            }
        }
        .buttonStyle(PlainButtonStyle()) // Remove any system button animations
        .animation(nil) // Disable all animations on the button
        .accessibilityLabel(isRecording ? String(localized: "situation.voice.stop") : String(localized: "situation.voice.start"))
        .accessibilityHint(String(localized: "situation.voice.toggle.hint"))
    }
}
