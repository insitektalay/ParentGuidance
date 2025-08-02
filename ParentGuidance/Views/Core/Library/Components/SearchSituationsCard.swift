//
//  SearchSituationsCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 18/07/2025.
//

import SwiftUI

struct SearchSituationsCard: View {
    let familyId: String?
    let onSearchSituations: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var situationCount: Int = 0
    @State private var isLoading: Bool = false
    @State private var hasError: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(SemanticColors.accentBlue)
                
                Text(String(localized: "library.searchCard.title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
            }
            
            // Description and situation count
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "library.searchCard.subtitle"))
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.secondaryText)
                
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .foregroundColor(SemanticColors.tertiaryText)
                        
                        Text(String(localized: "library.searchCard.loading"))
                            .font(.system(size: 12))
                            .foregroundColor(SemanticColors.tertiaryText)
                    }
                } else if hasError {
                    Text(String(localized: "library.searchCard.error"))
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.tertiaryText)
                } else {
                    if situationCount > 0 {
                        Text(String(localized: "library.searchCard.count \(situationCount)"))
                            .font(.system(size: 12))
                            .foregroundColor(SemanticColors.tertiaryText)
                    } else {
                        Text(String(localized: "library.searchCard.empty"))
                            .font(.system(size: 12))
                            .foregroundColor(SemanticColors.tertiaryText)
                    }
                }
            }
            
            // Action button
            HStack(spacing: 12) {
                Button(action: onSearchSituations) {
                    Text(String(localized: "library.searchCard.button"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(SemanticColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isLoading)
                
                Spacer()
            }
        }
        .padding(16)
        .background(SemanticColors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SemanticColors.border, lineWidth: 1)
        )
        .if(colorScheme == .light) { view in
            view.cardShadow()
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            loadSituationCount()
        }
    }
    
    private func loadSituationCount() {
        guard let familyId = familyId else {
            hasError = true
            return
        }
        
        isLoading = true
        hasError = false
        
        Task {
            do {
                // Use existing ConversationService to get situation count
                let situations = try await ConversationService.shared.getAllSituations(familyId: familyId)
                
                await MainActor.run {
                    self.situationCount = situations.count
                    self.isLoading = false
                }
            } catch {
                print("❌ Error loading situation count: \(error)")
                await MainActor.run {
                    self.hasError = true
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    SearchSituationsCard(familyId: "preview-family-id") {
        print("Search situations tapped")
    }
    .padding()
    .background(SemanticColors.primaryBackground)
}
