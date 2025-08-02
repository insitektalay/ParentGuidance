//
//  DeletedCopingStrategyCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 30/07/2025.
//

import SwiftUI

struct DeletedCopingStrategyCard: View {
    let deletedStrategy: DeletedCopingStrategy
    let onRestore: () -> Void
    let onPermanentDelete: () -> Void
    
    @State private var showingRestoreConfirmation = false
    @State private var showingPermanentDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main content
            Text(deletedStrategy.content)
                .font(.system(size: 16))
                .foregroundColor(SemanticColors.primaryText)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            
            // Date info
            HStack {
                Text("Deleted \(formatDate(deletedStrategy.deletedAt))")
                    .font(.system(size: 12))
                    .foregroundColor(SemanticColors.tertiaryText)
                
                Spacer()
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    showingRestoreConfirmation = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                        
                        Text(String(localized: "library.deleted.action.restore"))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(SemanticColors.accentBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(SemanticColors.accentBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Button(action: {
                    showingPermanentDeleteConfirmation = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .medium))
                        
                        Text(String(localized: "library.deleted.action.permanentDelete"))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(SemanticColors.accent.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(SemanticColors.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SemanticColors.cardBackground) // Slightly darker than regular cards
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SemanticColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .confirmationDialog("Restore Coping Strategy", isPresented: $showingRestoreConfirmation) {
            Button("Restore") {
                onRestore()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will restore the coping strategy back to your active strategies.")
        }
        .confirmationDialog("Permanently Delete", isPresented: $showingPermanentDeleteConfirmation) {
            Button("Permanently Delete", role: .destructive) {
                onPermanentDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete this coping strategy. This action cannot be undone.")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleDeletedStrategy = DeletedCopingStrategy(
        id: UUID(),
        originalInsightId: UUID(),
        familyId: "family-123",
        childId: "child-456",
        situationId: "situation-789",
        content: "Taking deep breaths and counting to 10 when feeling overwhelmed helps regulate emotions during difficult transitions.",
        deletedAt: Date(),
        deletedReason: nil
    )
    
    return DeletedCopingStrategyCard(
        deletedStrategy: sampleDeletedStrategy,
        onRestore: { print("Restore tapped") },
        onPermanentDelete: { print("Permanent delete tapped") }
    )
    .padding()
    .background(SemanticColors.primaryBackground)
}