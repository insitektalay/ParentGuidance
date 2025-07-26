import SwiftUI

struct TranscribingOverlay: View {
    @State private var animationPhase: Int = 0
    
    var body: some View {
        VStack(spacing: 8) {
            // Animated dots
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(ColorPalette.terracotta)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .opacity(animationPhase == index ? 1.0 : 0.6)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: false),
                            value: animationPhase
                        )
                }
            }
            
            // Transcribing text
            Text("Transcribing...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorPalette.terracotta)
                .opacity(0.9)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ColorPalette.white.opacity(0.95))
                .shadow(color: ColorPalette.navy.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(1.0)
        .opacity(1.0)
        .onAppear {
            startAnimation()
        }
        .accessibilityLabel("Transcribing audio recording")
        .accessibilityAddTraits(.updatesFrequently)
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.3)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

#Preview {
    ZStack {
        ColorPalette.navy
            .ignoresSafeArea()
        
        TranscribingOverlay()
    }
}