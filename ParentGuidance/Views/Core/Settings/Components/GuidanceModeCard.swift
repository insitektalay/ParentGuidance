//
//  GuidanceModeCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct GuidanceModeCard: View {
    let mode: GuidanceStructureMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Mode icon
                Image(systemName: mode.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.6))
                    .frame(width: 24, height: 24)
                
                // Mode info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(mode.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ColorPalette.white)
                        
                        Text(mode.sectionCount)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ColorPalette.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    Text(mode.description)
                        .font(.system(size: 13))
                        .foregroundColor(ColorPalette.white.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.4))
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .padding(16)
            .background(
                Color(red: 0.21, green: 0.22, blue: 0.33)
                    .opacity(isSelected ? 1.0 : 0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? ColorPalette.brightBlue.opacity(0.4) : ColorPalette.white.opacity(0.1), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
