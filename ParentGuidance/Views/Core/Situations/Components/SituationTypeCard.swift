//
//  SituationTypeCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 24/07/2025.
//

import SwiftUI

struct SituationTypeCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let situationType: SituationType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Text(situationType.emoji)
                    .font(.system(size: 36))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStringKey(situationType.titleKey))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(SemanticColors.primaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(LocalizedStringKey(situationType.subtitleKey))
                        .font(.system(size: 15))
                        .foregroundColor(SemanticColors.secondaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(SemanticColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? SemanticColors.accent : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .if(colorScheme == .light) { view in
                        view.cardShadow()
                    }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}