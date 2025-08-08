import SwiftUI

struct RegeneratableSituationCard: View {
    let situation: Situation
    let hasGuidance: Bool
    let isRegenerating: Bool
    let selectionManager: LibrarySelectionManager?
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void
    let onRegenerate: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var showingDeleteButton: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var isSelected: Bool {
        guard let manager = selectionManager else { return false }
        return manager.isSelected(situationId: situation.id)
    }
    
    private var showCheckbox: Bool {
        guard let manager = selectionManager else { return false }
        return manager.isInSelectionMode
    }
    
    var body: some View {
        ZStack {
            // Background delete button (revealed when swiped)
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        dragOffset = 0
                        showingDeleteButton = false
                    }
                    onDelete()
                }) {
                    VStack {
                        Image(systemName: "trash")
                            .font(.system(size: 20, weight: .medium))
                        Text("Delete")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(width: 80)
                }
                .frame(maxHeight: .infinity)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .opacity(showingDeleteButton ? 1 : 0)
            
            // Main card content
            VStack(spacing: 0) {
                // Top section with icon, title, date, and action buttons
                HStack(alignment: .center, spacing: 12) {
                    // Checkbox (shown only in selection mode)
                    if showCheckbox {
                        Button(action: {
                            selectionManager?.toggleSelection(situationId: situation.id)
                        }) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(isSelected ? SemanticColors.accent : SemanticColors.secondaryText)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Icon
                    Image(systemName: SituationCard.getIconForEmoji(SituationCard.getEmojiForSituation(situation)))
                        .font(.system(size: 20))
                        .foregroundColor(SemanticColors.primaryText)
                        .frame(width: 20, height: 20)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 2) {
                        Text(situation.title)
                            .font(.system(size: 16))
                            .foregroundColor(SemanticColors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(SituationCard.formatDate(situation.createdAt))
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.tertiaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        // Trash delete button
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(SemanticColors.secondaryText)
                        }
                        .accessibilityLabel("Delete")
                        .accessibilityHint("Double tap to delete this situation")
                        
                        // Star favorite button
                        Button(action: onToggleFavorite) {
                            Image(systemName: situation.isFavorited ? "star.fill" : "star")
                                .font(.system(size: 16))
                                .foregroundColor(situation.isFavorited ? SemanticColors.accent : SemanticColors.secondaryText)
                                .animation(.easeInOut(duration: 0.2), value: situation.isFavorited)
                        }
                        .accessibilityLabel(situation.isFavorited ? String(localized: "action.removeFromFavorites") : String(localized: "action.addToFavorites"))
                        .accessibilityHint(String(localized: "accessibility.favorite.toggle"))
                    }
                }
                .padding(12)
                
                // Regenerate section (shown when guidance is missing)
                if !hasGuidance {
                    VStack(spacing: 8) {
                        Divider()
                            .background(SemanticColors.border)
                        
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.orange)
                            
                            Text("Guidance needs regeneration")
                                .font(.system(size: 14))
                                .foregroundColor(SemanticColors.secondaryText)
                            
                            Spacer()
                            
                            Button(action: onRegenerate) {
                                HStack(spacing: 4) {
                                    if isRegenerating {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .frame(width: 14, height: 14)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    Text(isRegenerating ? "Regenerating..." : "Regenerate")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isRegenerating ? Color.gray : SemanticColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .disabled(isRegenerating)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                    }
                }
            }
            .background(
                isSelected ? 
                    SemanticColors.accent.opacity(0.2) : 
                    SemanticColors.cardBackground
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? SemanticColors.accent.opacity(0.6) : SemanticColors.border, 
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .if(colorScheme == .light) { view in
                view.cardShadow()
            }
            .offset(x: dragOffset)
            .onTapGesture {
                if showingDeleteButton {
                    // If delete button is showing, hide it instead of navigating
                    withAnimation(.easeInOut(duration: 0.3)) {
                        dragOffset = 0
                        showingDeleteButton = false
                    }
                } else if showCheckbox {
                    // In selection mode, tap toggles selection
                    selectionManager?.toggleSelection(situationId: situation.id)
                } else if hasGuidance {
                    // Normal mode with guidance, navigate to detail
                    onTap()
                }
                // If no guidance, tapping does nothing (must use Regenerate button)
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        // Only respond to primarily horizontal swipes (left swipe for delete)
                        let horizontalMovement = abs(value.translation.width)
                        let verticalMovement = abs(value.translation.height)
                        
                        // Only activate horizontal swipe if it's more horizontal than vertical
                        // and it's a left swipe (negative width)
                        if horizontalMovement > verticalMovement && value.translation.width < 0 {
                            dragOffset = max(value.translation.width, -80) // Limit to delete button width
                        }
                    }
                    .onEnded { value in
                        let horizontalMovement = abs(value.translation.width)
                        let verticalMovement = abs(value.translation.height)
                        
                        // Only process horizontal swipe gesture if it was primarily horizontal
                        if horizontalMovement > verticalMovement {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if value.translation.width < -40 { // Threshold for showing delete
                                    dragOffset = -80
                                    showingDeleteButton = true
                                } else {
                                    dragOffset = 0
                                    showingDeleteButton = false
                                }
                            }
                        }
                    }
            )
        }
    }
}