import SwiftUI

struct MicButton: View {
    @Binding var isRecording: Bool
    let action: () -> Void
    
    @State private var pulseScale: Double = 1.0
    @State private var glowOpacity: Double = 0.0
    
    var body: some View {
        Button(action: {
            isRecording.toggle()
            action()
        }) {
            ZStack {
                // Outer glow effect when recording
                if isRecording {
                    Circle()
                        .fill(Color.red.opacity(glowOpacity))
                        .frame(width: 80, height: 80)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                            value: glowOpacity
                        )
                }
                
                // Main button
                Circle()
                    .fill(isRecording ? Color.red : ColorPalette.terracotta)
                    .frame(width: 56, height: 56)
                    .scaleEffect(isRecording ? pulseScale : 1.0)
                    .animation(
                        isRecording ? 
                        Animation.easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true) : 
                        Animation.easeInOut(duration: 0.2),
                        value: pulseScale
                    )
                
                // Microphone icon
                Image(systemName: isRecording ? "mic.fill" : "mic.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(ColorPalette.white)
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isRecording)
                
                // Voice input indicator waves
                if isRecording {
                    HStack(spacing: 2) {
                        ForEach(0..<3) { index in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(ColorPalette.white.opacity(0.8))
                                .frame(width: 2, height: CGFloat.random(in: 8...16))
                                .animation(
                                    Animation.easeInOut(duration: 0.3)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.1),
                                    value: isRecording
                                )
                        }
                    }
                    .offset(y: 25)
                }
            }
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                pulseScale = 1.15
                glowOpacity = 0.4
            } else {
                pulseScale = 1.0
                glowOpacity = 0.0
            }
        }
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
        .accessibilityHint("Double tap to toggle voice recording")
    }
}
