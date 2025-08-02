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
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                // Main content
                Text(insight.content)
                    .font(.system(size: 16))
                    .foregroundColor(SemanticColors.primaryText)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                
                // Date and category info
                HStack {
                    // Category or subcategory badge
                    if let subcategory = insight.subcategory {
                        Text(subcategory.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SemanticColors.accentBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(SemanticColors.accentBlue.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Text(insight.category.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SemanticColors.accentBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(SemanticColors.accentBlue.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Spacer()
                    
                    Text(formatDate(insight.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.tertiaryText)
                }
            }
            
            // Delete button in upper right corner
            Button(action: {
                showingDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SemanticColors.tertiaryText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SemanticColors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SemanticColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .cardShadow()
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
    .background(SemanticColors.primaryBackground)
}
