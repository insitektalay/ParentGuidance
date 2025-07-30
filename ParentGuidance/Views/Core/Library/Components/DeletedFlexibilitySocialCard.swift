//
//  DeletedFlexibilitySocialCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 30/07/2025.
//

import SwiftUI

struct DeletedFlexibilitySocialCard: View {
    let deletedInsight: DeletedFlexibilitySocialInsight
    let onRestore: () -> Void
    let onPermanentDelete: () -> Void
    
    @State private var showingRestoreConfirmation = false
    @State private var showingPermanentDeleteConfirmation = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                // Main content
                Text(deletedInsight.content)
                    .font(.system(size: 16))
                    .foregroundColor(ColorPalette.white.opacity(0.9))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                
                // Date info
                HStack {
                    Text(String(localized: "regulation.archive.deleted.date", defaultValue: "Deleted \(formatDate(deletedInsight.deletedAt))"))
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
        .confirmationDialog(String(localized: "regulation.archive.restore.title"), isPresented: $showingRestoreConfirmation) {
            Button(String(localized: "regulation.archive.restore.button")) {
                onRestore()
            }
            Button(String(localized: "common.button.cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "regulation.archive.restore.message"))
        }
        .confirmationDialog(String(localized: "regulation.archive.permanentDelete.title"), isPresented: $showingPermanentDeleteConfirmation) {
            Button(String(localized: "regulation.archive.permanentDelete.button"), role: .destructive) {
                onPermanentDelete()
            }
            Button(String(localized: "common.button.cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "regulation.archive.permanentDelete.message"))
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleDeletedInsight = DeletedFlexibilitySocialInsight(
        id: UUID(),
        originalInsightId: UUID(),
        familyId: "family-123",
        childId: "child-456",
        situationId: "situation-789",
        content: "Shows challenges with social flexibility when plans change unexpectedly, particularly in group settings with peers.",
        deletedAt: Date(),
        deletedReason: nil
    )
    
    return DeletedFlexibilitySocialCard(
        deletedInsight: sampleDeletedInsight,
        onRestore: { print("Restore tapped") },
        onPermanentDelete: { print("Permanent delete tapped") }
    )
    .padding()
    .background(ColorPalette.navy)
}
