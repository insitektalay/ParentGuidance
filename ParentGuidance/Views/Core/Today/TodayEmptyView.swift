//
//  TodayEmptyView.swift
//  ParentGuidance
//
//  Created by alex kerss on 29/06/2025.
//

import SwiftUI

struct TodayEmptyView: View {
    let onCreateFirstSituation: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            VStack(spacing: 24) {
                // Main headline
                Text("Let's build your daily routine support")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(ColorPalette.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 32)
                
                // Subtitle
                Text("Start by describing a parenting situation you're facing with Alex")
                    .font(.system(size: 18))
                    .foregroundColor(ColorPalette.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 32)
                
                // Description text
                Text("The more situations you add, the more organized guidance you'll have for your daily routine")
                    .font(.system(size: 16))
                    .foregroundColor(ColorPalette.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
                
                // Create First Situation button
                Button(action: onCreateFirstSituation) {
                    Text("Create Your First Situation")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(ColorPalette.terracotta)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                
                // Footer instruction
                Text("Tap the + New tab below to get started")
                    .font(.system(size: 16))
                    .foregroundColor(ColorPalette.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
    }
}

#Preview {
    TodayEmptyView(
        onCreateFirstSituation: {}
    )
}
