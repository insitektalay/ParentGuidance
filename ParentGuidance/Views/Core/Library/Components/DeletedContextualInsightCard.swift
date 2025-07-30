//
//  DeletedContextualInsightCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 30/07/2025.
//

import SwiftUI

struct DeletedContextualInsightCard: View {
    let insight: DeletedContextualInsight
    let onRestore: () -> Void
    let onPermanentDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with category and deleted date
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: insight.category.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ColorPalette.brightBlue)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.category.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    if let subcategory = insight.subcategory {
                        Text(subcategory.displayName)
                            .font(.system(size: 12))
                            .foregroundColor(ColorPalette.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Deleted")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ColorPalette.terracotta)
                    
                    Text(DateFormatter.shortDate.string(from: insight.deletedAt))
                        .font(.system(size: 10))
                        .foregroundColor(ColorPalette.white.opacity(0.5))
                }
            }
            
            // Content
            Text(insight.content)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.8))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // Deletion reason if available
            if let reason = insight.deletedReason, !reason.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                    
                    Text("Reason: \(reason)")
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                        .italic()
                }
                .padding(.top, 4)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onRestore) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                        
                        Text(String(localized: "library.deleted.action.restore"))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(ColorPalette.brightBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(ColorPalette.brightBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Button(action: onPermanentDelete) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .medium))
                        
                        Text(String(localized: "library.deleted.action.permanentDelete"))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(ColorPalette.terracotta.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(ColorPalette.terracotta.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color(red: 0.21, green: 0.22, blue: 0.33))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

#Preview {
    DeletedContextualInsightCard(
        insight: DeletedContextualInsight(
            id: UUID(),
            originalInsightId: "preview-id",
            familyId: "preview-family",
            childId: "preview-child",
            category: .familyContext,
            subcategory: nil,
            content: "This is a preview of a deleted contextual insight that shows how the content looks when displayed in the card format.",
            sourceSituationId: "preview-situation",
            deletedAt: Date(),
            deletedReason: "User requested deletion",
            createdAt: "2025-07-30T12:00:00Z",
            updatedAt: "2025-07-30T12:00:00Z"
        ),
        onRestore: { print("Restore tapped") },
        onPermanentDelete: { print("Permanent delete tapped") }
    )
    .padding()
    .background(ColorPalette.navy)
}

