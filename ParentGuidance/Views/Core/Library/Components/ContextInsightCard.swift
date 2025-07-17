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
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    private let deleteThreshold: CGFloat = -80
    private let deleteButtonWidth: CGFloat = 80
    
    var body: some View {
        HStack(spacing: 0) {
            // Main content
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
                
                // Date
                Text(formatDate(insight.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(ColorPalette.white.opacity(0.5))
            }
            .padding(16)
            .background(Color(red: 0.21, green: 0.22, blue: 0.33))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .offset(x: dragOffset.width)
            .animation(.easeOut(duration: 0.2), value: dragOffset)
            
            // Delete button (revealed when swiping left)
            if dragOffset.width < -10 {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                        .frame(width: deleteButtonWidth, height: 60)
                        .background(ColorPalette.terracotta)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .transition(.move(edge: .trailing))
                .animation(.easeOut(duration: 0.2), value: dragOffset)
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    
                    // Only allow left swipe (negative values)
                    if value.translation.width < 0 {
                        dragOffset = CGSize(
                            width: max(value.translation.width, -deleteButtonWidth),
                            height: 0
                        )
                    }
                }
                .onEnded { value in
                    isDragging = false
                    
                    // Snap to delete position or return to original
                    if value.translation.width < deleteThreshold {
                        // Show delete button
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = CGSize(width: -deleteButtonWidth, height: 0)
                        }
                    } else {
                        // Return to original position
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = .zero
                        }
                    }
                }
        )
        .onTapGesture {
            // Tap anywhere to close the delete button
            if dragOffset.width < 0 {
                withAnimation(.easeOut(duration: 0.2)) {
                    dragOffset = .zero
                }
            }
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
