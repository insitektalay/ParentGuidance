//
//  SituationTypeCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 24/07/2025.
//

import SwiftUI

struct SituationTypeCard: View {
    let situationType: SituationType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(situationType.emoji)
                    .font(.system(size: 32))
                
                Text(LocalizedStringKey(situationType.titleKey))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ColorPalette.white)
                    .multilineTextAlignment(.leading)
                
                Text(LocalizedStringKey(situationType.subtitleKey))
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ColorPalette.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? ColorPalette.terracotta : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}