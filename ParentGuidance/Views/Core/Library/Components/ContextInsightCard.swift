//
//  ContextInsightCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 17/07/2025.
//

import SwiftUI

struct ContextInsightCard: View {
    let insight: ContextualInsight
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Subcategory (if available)
            if let subcategory = insight.subcategory {
                Text(subcategory.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ColorPalette.brightBlue)
            }
            
            // Insight content
            Text(insight.content)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            
            // Bottom row with date and delete button
            HStack(alignment: .bottom) {
                // Date
                Text(formatDate(insight.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(ColorPalette.white.opacity(0.5))
                
                Spacer()
                
                // Delete button
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                }
                .buttonStyle(PlainButtonStyle())
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
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    VStack(spacing: 16) {
        ContextInsightCard(
            insight: ContextualInsight(
                familyId: "preview-family",
                childId: nil,
                category: .familyContext,
                subcategory: nil,
                content: "Child responds well to calm, quiet environments during homework time",
                sourceSituationId: "preview-situation"
            ),
            onDelete: {
                print("Delete tapped")
            }
        )
        
        ContextInsightCard(
            insight: ContextualInsight(
                familyId: "preview-family",
                childId: nil,
                category: .provenRegulationTools,
                subcategory: .physicalSensory,
                content: "Deep pressure from weighted blanket helps with bedtime routine",
                sourceSituationId: "preview-situation"
            ),
            onDelete: {
                print("Delete tapped")
            }
        )
    }
    .padding()
    .background(ColorPalette.navy)
}
