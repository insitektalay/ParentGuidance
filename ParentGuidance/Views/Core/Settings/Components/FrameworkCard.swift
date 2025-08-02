//
//  FrameworkCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct FrameworkCard: View {
    @Environment(\.colorScheme) private var colorScheme
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
                    .foregroundColor(isActive ? SemanticColors.accentBlue : SemanticColors.tertiaryText)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(framework.frameworkName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Text(isActive ? String(localized: "framework.status.active") : String(localized: "framework.status.inactive"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isActive ? SemanticColors.accentBlue : SemanticColors.tertiaryText)
                }
                
                Spacer()
                
                // Toggle switch
                Button(action: onToggle) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isActive ? SemanticColors.accentBlue : SemanticColors.tertiaryText)
                        .frame(width: 44, height: 24)
                        .overlay(
                            Circle()
                                .fill(SemanticColors.primaryText)
                                .frame(width: 20, height: 20)
                                .offset(x: isActive ? 10 : -10)
                        )
                        .animation(.easeInOut(duration: 0.2), value: isActive)
                }
            }
            
            // Framework description
            Text(framework.notificationText)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.secondaryText)
                .lineLimit(2)
            
            // Framework actions
            HStack(spacing: 12) {
                Button(String(localized: "framework.action.guide")) {
                    // TODO: Navigate to framework guide
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(SemanticColors.accentBlue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Button(String(localized: "framework.action.remove")) {
                    onRemove()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(SemanticColors.accent, lineWidth: 1)
                )
                
                Spacer()
            }
        }
        .padding(16)
        .background(SemanticColors.cardBackground.opacity(isActive ? 1.0 : 0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? SemanticColors.accentBlue.opacity(0.3) : SemanticColors.tertiaryText.opacity(0.1), lineWidth: 1)
        )
        .if(colorScheme == .light) { view in
            view.cardShadow()
        }
    }
}
