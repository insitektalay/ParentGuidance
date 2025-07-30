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
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                // Main content
                Text(deletedStrategy.content)
                    .font(.system(size: 16))
                    .foregroundColor(ColorPalette.white.opacity(0.9))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                
                // Date info
                HStack {
                    Text("Deleted \(formatDate(deletedStrategy.deletedAt))")
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                    
                    Spacer()
                }
            }
            
            // Action buttons
            VStack(spacing: 8) {
                // Restore button
                Button(action: {
                    showingRestoreConfirmation = true
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.brightBlue)
                }
                
                // Permanent delete button
                Button(action: {
                    showingPermanentDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.15, green: 0.16, blue: 0.25)) // Slightly darker than regular cards
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
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
    .background(ColorPalette.navy)
}