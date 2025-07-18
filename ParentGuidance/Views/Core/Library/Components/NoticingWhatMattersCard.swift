//
//  NoticingWhatMattersCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 18/07/2025.
//

import SwiftUI

struct NoticingWhatMattersCard: View {
    let familyId: String?
    let onViewInsights: () -> Void
    
    @State private var insightCounts: [RegulationCategory: Int] = [:]
    @State private var isLoading: Bool = false
    @State private var hasError: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20))
                    .foregroundColor(ColorPalette.brightBlue)
                
                Text("Noticing What Matters")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ColorPalette.white)
                
                Spacer()
            }
            
            // Description and insight count
            VStack(alignment: .leading, spacing: 8) {
                Text("Child regulation insights")
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.white.opacity(0.8))
                
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                        
                        Text("Loading insights...")
                            .font(.system(size: 12))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                    }
                } else if hasError {
                    Text("Unable to load insights")
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                } else {
                    let totalInsights = insightCounts.values.reduce(0, +)
                    if totalInsights > 0 {
                        Text("\(totalInsights) insights across \(insightCounts.count) categories")
                            .font(.system(size: 12))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                    } else {
                        Text("No insights collected yet")
                            .font(.system(size: 12))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                    }
                }
            }
            
            // Action button
            HStack(spacing: 12) {
                Button(action: onViewInsights) {
                    Text("View Insights")
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
            loadInsightCounts()
        }
    }
    
    private func loadInsightCounts() {
        guard let familyId = familyId else {
            hasError = true
            return
        }
        
        isLoading = true
        hasError = false
        
        Task {
            do {
                let counts = try await ContextualInsightService.shared.getRegulationInsightCounts(familyId: familyId)
                
                await MainActor.run {
                    self.insightCounts = counts
                    self.isLoading = false
                }
            } catch {
                print("❌ Error loading regulation insight counts: \(error)")
                await MainActor.run {
                    self.hasError = true
                    self.isLoading = false
                }
            }
        }
    }
}
