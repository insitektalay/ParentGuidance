//
//  GuidanceModeCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct GuidanceModeCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let mode: GuidanceStructureMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Mode icon
                Image(systemName: mode.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? SemanticColors.accentBlue : SemanticColors.tertiaryText)
                    .frame(width: 24, height: 24)
                
                // Mode info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(mode.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(SemanticColors.primaryText)
                        
                        Text(mode.sectionCount)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(SemanticColors.tertiaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(SemanticColors.tertiaryText)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    Text(mode.description)
                        .font(.system(size: 13))
                        .foregroundColor(SemanticColors.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? SemanticColors.accentBlue : SemanticColors.tertiaryText)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .padding(16)
            .background(SemanticColors.cardBackground.opacity(isSelected ? 1.0 : 0.6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? SemanticColors.accentBlue.opacity(0.4) : SemanticColors.tertiaryText.opacity(0.1), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .if(colorScheme == .light) { view in
            view.cardShadow()
        }
    }
}
