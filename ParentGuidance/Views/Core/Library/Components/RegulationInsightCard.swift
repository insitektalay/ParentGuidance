//
//  RegulationInsightCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 18/07/2025.
//

import SwiftUI

struct RegulationInsightCard: View {
    let insight: ChildRegulationInsight
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                // Main content
                Text(insight.content)
                    .font(.system(size: 16))
                    .foregroundColor(ColorPalette.white.opacity(0.9))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                
                // Date and category info
                HStack {
                    Text(insight.category.parentFriendlyName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ColorPalette.brightBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ColorPalette.brightBlue.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Spacer()
                    
                    Text(formatDate(insight.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                }
            }
            
            // Delete button in upper right corner
            Button(action: {
                showingDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorPalette.white.opacity(0.6))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.21, green: 0.22, blue: 0.33))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Delete Insight", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this insight? This action cannot be undone.")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleInsight = ChildRegulationInsight(
        familyId: "family-123",
        childId: "child-456",
        situationId: "situation-789",
        category: .core,
        content: "Shows strong emotional responses when transitioning between activities, particularly when moving from preferred to less preferred tasks."
    )
    
    return RegulationInsightCard(insight: sampleInsight) {
        print("Delete tapped")
    }
    .padding()
    .background(ColorPalette.navy)
}
