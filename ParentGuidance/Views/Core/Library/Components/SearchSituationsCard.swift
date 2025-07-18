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
    
    @State private var situationCount: Int = 0
    @State private var isLoading: Bool = false
    @State private var hasError: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(ColorPalette.brightBlue)
                
                Text("Search Situations")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ColorPalette.white)
                
                Spacer()
            }
            
            // Description and situation count
            VStack(alignment: .leading, spacing: 8) {
                Text("Find and organize your parenting situations")
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.white.opacity(0.8))
                
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                        
                        Text("Loading situations...")
                            .font(.system(size: 12))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                    }
                } else if hasError {
                    Text("Unable to load situations")
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                } else {
                    if situationCount > 0 {
                        Text("\(situationCount) situations available to search")
                            .font(.system(size: 12))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                    } else {
                        Text("No situations collected yet")
                            .font(.system(size: 12))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                    }
                }
            }
            
            // Action button
            HStack(spacing: 12) {
                Button(action: onSearchSituations) {
                    Text("Search Situations")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(ColorPalette.terracotta)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isLoading)
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(red: 0.21, green: 0.22, blue: 0.33)) // #363853 equivalent
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
        )
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
    .background(ColorPalette.navy)
}
