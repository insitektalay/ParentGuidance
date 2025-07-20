//
//  YourChildsWorldCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 17/07/2025.
//

import SwiftUI

struct YourChildsWorldCard: View {
    let familyId: String?
    let onViewInsights: () -> Void
    
    @State private var insightCounts: [ContextCategory: Int] = [:]
    @State private var isLoading: Bool = false
    @State private var hasError: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(ColorPalette.brightBlue)
                
                Text(String(localized: "library.childsWorld.title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ColorPalette.white)
                
                Spacer()
            }
            
            // Description and insight count
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "library.childsWorld.subtitle"))
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.white.opacity(0.8))
                
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                        
                        Text(String(localized: "library.childsWorld.loading"))
                            .font(.system(size: 12))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                    }
                } else if hasError {
                    Text(String(localized: "library.childsWorld.error"))
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                } else {
                    let totalInsights = insightCounts.values.reduce(0, +)
                    if totalInsights > 0 {
                        Text(String.localizedStringWithFormat(String(localized: "library.childsWorld.count %lld %lld"), totalInsights, insightCounts.count))
                            .font(.system(size: 12))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                    } else {
                        Text(String(localized: "library.childsWorld.empty"))
                            .font(.system(size: 12))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                    }
                }
            }
            
            // Action button
            HStack(spacing: 12) {
                Button(action: onViewInsights) {
                    Text(String(localized: "library.childsWorld.button"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(ColorPalette.terracotta)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
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
            Task {
                await loadInsightCounts()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task {
                await loadInsightCounts()
            }
        }
    }
    
    @MainActor
    private func loadInsightCounts() async {
        guard let familyId = familyId else {
            print("❌ No family ID available for YourChildsWorldCard")
            return
        }
        
        isLoading = true
        hasError = false
        
        do {
            insightCounts = try await ContextualInsightService.shared.getInsightCounts(familyId: familyId)
            print("✅ Loaded insight counts: \(insightCounts)")
        } catch {
            print("❌ Failed to load insight counts: \(error)")
            hasError = true
        }
        
        isLoading = false
    }
}

#Preview {
    YourChildsWorldCard(familyId: "preview-family-id") {
        print("View insights tapped")
    }
    .padding()
    .background(ColorPalette.navy)
}