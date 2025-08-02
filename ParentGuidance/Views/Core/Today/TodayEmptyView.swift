//
//  TodayEmptyView.swift
//  ParentGuidance
//
//  Created by alex kerss on 29/06/2025.
//

import SwiftUI

struct TodayEmptyView: View {
    @Environment(\.colorScheme) private var colorScheme
    let onCreateFirstSituation: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            VStack(spacing: 24) {
                // Main headline
                Text(String(localized: "today.empty.title"))
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(SemanticColors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 32)
                
                // Subtitle
                Text(String(localized: "today.empty.subtitle"))
                    .font(.system(size: 18))
                    .foregroundColor(SemanticColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 32)
                
                // Description text
                Text(String(localized: "today.empty.description"))
                    .font(.system(size: 16))
                    .foregroundColor(SemanticColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
                
                // Create First Situation button
                Button(action: onCreateFirstSituation) {
                    Text(String(localized: "today.empty.createButton"))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(SemanticColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .modifier(ConditionalShadow(colorScheme: colorScheme))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                
                // Footer instruction
                Text(String(localized: "today.empty.instruction"))
                    .font(.system(size: 16))
                    .foregroundColor(SemanticColors.tertiaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SemanticColors.primaryBackground)
    }
}

#Preview {
    TodayEmptyView(
        onCreateFirstSituation: {}
    )
}

// MARK: - Conditional Shadow Modifier
struct ConditionalShadow: ViewModifier {
    let colorScheme: ColorScheme
    
    func body(content: Content) -> some View {
        if colorScheme == .light {
            content.cardShadow()
        } else {
            content
        }
    }
}
