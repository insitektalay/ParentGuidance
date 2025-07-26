import SwiftUI

struct MicButton: View {
    let isRecording: Bool
    let isTranscribing: Bool
    let action: () -> Void
    
    var body: some View {
        
        Button(action: action) {
            ZStack {
                // Static button - no animations at all
                Circle()
                    .fill(buttonBackgroundColor)
                    .frame(width: 56, height: 56)
                
                // Static icon - no animations
                Image(systemName: buttonIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(iconColor)
                
                // Only show animation effects when actually recording (not when transcribing)
                if isRecording && !isTranscribing {
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
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(String(localized: "situation.voice.toggle.hint"))
    }
    
    // MARK: - Computed Properties
    
    private var buttonBackgroundColor: Color {
        if isTranscribing {
            return ColorPalette.white
        } else if isRecording {
            return Color.red
        } else {
            return ColorPalette.terracotta
        }
    }
    
    private var iconColor: Color {
        if isTranscribing {
            return ColorPalette.terracotta
        } else {
            return ColorPalette.white
        }
    }
    
    private var buttonIcon: String {
        if isTranscribing {
            return "checkmark.circle.fill"
        } else if isRecording {
            return "stop.fill"
        } else {
            return "mic.fill"
        }
    }
    
    private var accessibilityLabel: String {
        if isTranscribing {
            return "Transcribing audio"
        } else if isRecording {
            return String(localized: "situation.voice.stop")
        } else {
            return String(localized: "situation.voice.start")
        }
    }
}
