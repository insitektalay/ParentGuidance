//
//  FilterButton.swift
//  ParentGuidance
//
//  Created by alex kerss on 04/07/2025.
//

import Foundation
import SwiftUI

struct FilterButton: View {
    let title: String
    let icon: String?
    let isActive: Bool
    let badgeCount: Int?
    let onTap: () -> Void
    
    init(
        title: String,
        icon: String? = nil,
        isActive: Bool = false,
        badgeCount: Int? = nil,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isActive = isActive
        self.badgeCount = badgeCount
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                // Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(foregroundColor)
                }
                
                // Title
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(foregroundColor)
                
                // Badge
                if let count = badgeCount, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(badgeTextColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(badgeBackgroundColor)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
    
    // MARK: - Computed Properties
    private var foregroundColor: Color {
        isActive ? ColorPalette.white : ColorPalette.white.opacity(0.7)
    }
    
    private var backgroundColor: Color {
        isActive ? ColorPalette.terracotta : Color.clear
    }
    
    private var borderColor: Color {
        isActive ? ColorPalette.terracotta : ColorPalette.white.opacity(0.2)
    }
    
    private var badgeTextColor: Color {
        isActive ? ColorPalette.terracotta : ColorPalette.white
    }
    
    private var badgeBackgroundColor: Color {
        isActive ? ColorPalette.white : ColorPalette.white.opacity(0.2)
    }
    
    private var accessibilityLabel: String {
        var label = title
        if let count = badgeCount, count > 0 {
            label += ", \(count) items"
        }
        if isActive {
            label += ", selected"
        }
        return label
    }
    
    private var accessibilityHint: String {
        isActive ? "Double tap to deselect" : "Double tap to select"
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            FilterButton(
                title: "Today",
                icon: "calendar.badge.clock",
                isActive: false,
                badgeCount: 3,
                onTap: {}
            )
            
            FilterButton(
                title: "This Week",
                icon: "calendar",
                isActive: true,
                badgeCount: 12,
                onTap: {}
            )
            
            FilterButton(
                title: "All Time",
                icon: "infinity",
                isActive: false,
                onTap: {}
            )
        }
        
        HStack(spacing: 12) {
            FilterButton(
                title: "Sleep",
                isActive: false,
                badgeCount: 5,
                onTap: {}
            )
            
            FilterButton(
                title: "Food",
                isActive: true,
                badgeCount: 8,
                onTap: {}
            )
            
            FilterButton(
                title: "Play",
                isActive: false,
                onTap: {}
            )
        }
    }
    .padding()
    .background(ColorPalette.navy)
}
