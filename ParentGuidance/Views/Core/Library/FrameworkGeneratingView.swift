//
//  FrameworkGeneratingView.swift
//  ParentGuidance
//
//  Created by alex kerss on 07/07/2025.
//

import SwiftUI

struct FrameworkGeneratingView: View {
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: Double = 1.0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animated loading indicator
            ZStack {
                // Outer ring with rotation animation
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                ColorPalette.terracotta.opacity(0.8),
                                ColorPalette.terracotta.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(
                        Animation.linear(duration: 2.0)
                            .repeatForever(autoreverses: false),
                        value: rotationAngle
                    )
                
                // Inner pulsing circle
                Circle()
                    .fill(ColorPalette.terracotta.opacity(0.6))
                    .frame(width: 20, height: 20)
                    .scaleEffect(pulseScale)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: pulseScale
                    )
            }
            .padding(.bottom, 40)
            
            // Main text
            Text("Generating your framework...")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(ColorPalette.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            
            // Subtitle
            Text("Analyzing your situations to create personalized guidance")
                .font(.system(size: 16))
                .foregroundColor(ColorPalette.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .onAppear {
            rotationAngle = 360
            pulseScale = 1.3
        }
    }
}

#Preview {
    FrameworkGeneratingView()
}
