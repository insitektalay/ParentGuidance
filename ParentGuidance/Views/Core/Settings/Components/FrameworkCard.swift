//
//  FrameworkCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct FrameworkCard: View {
    let framework: FrameworkRecommendation
    let isActive: Bool
    let onToggle: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Framework header with status
            HStack(spacing: 8) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(isActive ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.6))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(framework.frameworkName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ColorPalette.white)
                    
                    Text(isActive ? String(localized: "framework.status.active") : String(localized: "framework.status.inactive"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isActive ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.6))
                }
                
                Spacer()
                
                // Toggle switch
                Button(action: onToggle) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isActive ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.3))
                        .frame(width: 44, height: 24)
                        .overlay(
                            Circle()
                                .fill(ColorPalette.white)
                                .frame(width: 20, height: 20)
                                .offset(x: isActive ? 10 : -10)
                        )
                        .animation(.easeInOut(duration: 0.2), value: isActive)
                }
            }
            
            // Framework description
            Text(framework.notificationText)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.8))
                .lineLimit(2)
            
            // Framework actions
            HStack(spacing: 12) {
                Button(String(localized: "framework.action.guide")) {
                    // TODO: Navigate to framework guide
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(ColorPalette.brightBlue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Button(String(localized: "framework.action.remove")) {
                    onRemove()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorPalette.terracotta)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorPalette.terracotta, lineWidth: 1)
                )
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            Color(red: 0.21, green: 0.22, blue: 0.33)
                .opacity(isActive ? 1.0 : 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? ColorPalette.brightBlue.opacity(0.3) : ColorPalette.white.opacity(0.1), lineWidth: 1)
        )
    }
}
