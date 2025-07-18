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
                        .foregroundColor(ColorPalette.terracotta.opacity(0.8))
                } else {
                    let totalInsights = insightCounts.values.reduce(0, +)
                    Text(totalInsights == 0 ? "No insights yet" : "\(totalInsights) insight\(totalInsights == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                }
            }
            
            // View Insights button
            Button(action: onViewInsights) {
                HStack(spacing: 6) {
                    Text("View Insights")
                        .font(.system(size: 14, weight: .medium))
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 14))
                }
                .foregroundColor(ColorPalette.terracotta)
            }
            .disabled(isLoading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ColorPalette.white.opacity(0.05))
                .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
        )
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
