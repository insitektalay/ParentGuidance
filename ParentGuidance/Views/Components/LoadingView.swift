//
//  LoadingView.swift
//  ParentGuidance
//
//  Created by alex kerss on 10/07/2025.
//

import SwiftUI

struct LoadingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .stroke(SemanticColors.accent.opacity(0.3), lineWidth: 4)
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(SemanticColors.accent, lineWidth: 4)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                )
            
            Text(String(localized: "common.loading"))
                .font(.headline)
                .foregroundColor(SemanticColors.primaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SemanticColors.primaryBackground)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    LoadingView()
}