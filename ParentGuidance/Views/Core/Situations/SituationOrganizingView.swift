//
//  SituationOrganizingView.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/06/2025.
//

import SwiftUI

struct SituationOrganizingView: View {
    @Environment(\.colorScheme) private var colorScheme
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
                                SemanticColors.accent.opacity(0.8),
                                SemanticColors.accent.opacity(0.3),
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
                    .fill(SemanticColors.accent.opacity(0.6))
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
            Text(String(localized: "situation.organizing.title"))
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            
            // Subtitle
            Text(String(localized: "situation.organizing.subtitle"))
                .font(.system(size: 16))
                .foregroundColor(SemanticColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SemanticColors.primaryBackground)
        .onAppear {
            rotationAngle = 360
            pulseScale = 1.3
        }
    }
}

#Preview {
    SituationOrganizingView()
}
