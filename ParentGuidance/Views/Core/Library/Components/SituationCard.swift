import SwiftUI

struct SituationCard: View {
    let emoji: String
    let title: String
    let date: String
    let isFavorited: Bool
    let situationId: String?
    let selectionManager: LibrarySelectionManager?
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var showingDeleteButton: Bool = false
    
    private var isSelected: Bool {
        guard let situationId = situationId,
              let manager = selectionManager else { return false }
        return manager.isSelected(situationId: situationId)
    }
    
    private var showCheckbox: Bool {
        guard let manager = selectionManager else { return false }
        return manager.isInSelectionMode
    }
    
    // Legacy initializer for backward compatibility
    init(
        emoji: String,
        title: String,
        date: String,
        isFavorited: Bool = false,
        situationId: String? = nil,
        selectionManager: LibrarySelectionManager? = nil,
        onTap: @escaping () -> Void = {},
        onToggleFavorite: @escaping () -> Void = {},
        onDelete: @escaping () -> Void = {}
    ) {
        self.emoji = emoji
        self.title = title
        self.date = date
        self.isFavorited = isFavorited
        self.situationId = situationId
        self.selectionManager = selectionManager
        self.onTap = onTap
        self.onToggleFavorite = onToggleFavorite
        self.onDelete = onDelete
    }
    
    // New initializer for Situation models
    init(
        situation: Situation,
        selectionManager: LibrarySelectionManager? = nil,
        onTap: @escaping () -> Void = {},
        onToggleFavorite: @escaping () -> Void = {},
        onDelete: @escaping () -> Void = {}
    ) {
        self.emoji = Self.getEmojiForSituation(situation)
        self.title = situation.title
        self.date = Self.formatDate(situation.createdAt)
        self.isFavorited = situation.isFavorited
        self.situationId = situation.id
        self.selectionManager = selectionManager
        self.onTap = onTap
        self.onToggleFavorite = onToggleFavorite
        self.onDelete = onDelete
    }
    
    private var iconForEmoji: String {
        switch emoji {
        case "🦷":
            return "mouth" // Closest SF Symbol to tooth
        case "🛁":
            return "drop.fill" // Bathtub/water representation
        case "🚗":
            return "car.fill"
        case "🍽️":
            return "fork.knife"
        default:
            return "circle.fill"
        }
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
            HStack(alignment: .center, spacing: 12) {
                // Checkbox (shown only in selection mode)
                if showCheckbox {
                    Button(action: {
                        guard let situationId = situationId else { return }
                        selectionManager?.toggleSelection(situationId: situationId)
                    }) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? ColorPalette.terracotta : ColorPalette.white.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Icon
                Image(systemName: iconForEmoji)
                    .font(.system(size: 20))
                    .foregroundColor(ColorPalette.white)
                    .frame(width: 20, height: 20)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(date)
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                // Star favorite button
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorited ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundColor(isFavorited ? ColorPalette.terracotta : ColorPalette.white.opacity(0.7))
                        .animation(.easeInOut(duration: 0.2), value: isFavorited)
                }
                .accessibilityLabel(isFavorited ? String(localized: "action.removeFromFavorites") : String(localized: "action.addToFavorites"))
                .accessibilityHint(String(localized: "accessibility.favorite.toggle"))
            }
            .padding(12)
            .background(
                isSelected ? 
                    ColorPalette.terracotta.opacity(0.2) : 
                    Color(red: 0.21, green: 0.22, blue: 0.33) // #363853 equivalent
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? ColorPalette.terracotta.opacity(0.6) : ColorPalette.white.opacity(0.1), 
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    guard let situationId = situationId else { return }
                    selectionManager?.toggleSelection(situationId: situationId)
                } else {
                    // Normal mode, navigate to detail
                    onTap()
                }
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
    
    // MARK: - Static Helper Methods
    static func getEmojiForSituation(_ situation: Situation) -> String {
        // Comprehensive emoji mapping based on keywords in title/description
        let text = "\(situation.title) \(situation.description)".lowercased()
        
        // Health & hygiene
        if text.contains("teeth") || text.contains("brush") || text.contains("dental") {
            return "🦷"
        } else if text.contains("bath") || text.contains("shower") || text.contains("wash") {
            return "🛁"
        } else if text.contains("sick") || text.contains("medicine") || text.contains("doctor") {
            return "🏥"
        }
        
        // Sleep & bedtime
        else if text.contains("bedtime") || text.contains("sleep") || text.contains("nap") || text.contains("tired") {
            return "😴"
        } else if text.contains("nightmare") || text.contains("scared") || text.contains("dark") {
            return "🌙"
        }
        
        // Food & eating
        else if text.contains("dinner") || text.contains("lunch") || text.contains("breakfast") || text.contains("food") || text.contains("eat") {
            return "🍽️"
        } else if text.contains("snack") || text.contains("hungry") {
            return "🍎"
        }
        
        // Transportation
        else if text.contains("car") || text.contains("drive") || text.contains("pickup") || text.contains("drop off") {
            return "🚗"
        } else if text.contains("bus") || text.contains("transport") {
            return "🚌"
        }
        
        // School & learning
        else if text.contains("school") || text.contains("homework") || text.contains("study") || text.contains("teacher") {
            return "📚"
        } else if text.contains("reading") || text.contains("book") {
            return "📖"
        }
        
        // Play & activities
        else if text.contains("play") || text.contains("toy") || text.contains("game") {
            return "🎮"
        } else if text.contains("outside") || text.contains("park") || text.contains("playground") {
            return "🏞️"
        } else if text.contains("art") || text.contains("draw") || text.contains("craft") {
            return "🎨"
        }
        
        // Emotions & behavior
        else if text.contains("tantrum") || text.contains("meltdown") || text.contains("crying") {
            return "😭"
        } else if text.contains("angry") || text.contains("mad") || text.contains("frustrat") {
            return "😠"
        } else if text.contains("happy") || text.contains("excited") || text.contains("joy") {
            return "😊"
        } else if text.contains("sad") || text.contains("upset") {
            return "😢"
        }
        
        // Social & family
        else if text.contains("friend") || text.contains("social") || text.contains("sharing") {
            return "👥"
        } else if text.contains("sibling") || text.contains("brother") || text.contains("sister") {
            return "👨‍👩‍👧‍👦"
        }
        
        // Chores & responsibilities
        else if text.contains("chore") || text.contains("clean") || text.contains("tidy") {
            return "🧹"
        } else if text.contains("help") || text.contains("responsible") {
            return "🙋‍♀️"
        }
        
        // Default fallback
        else {
            return "💬"
        }
    }
    
    static func getIconForEmoji(_ emoji: String) -> String {
        switch emoji {
        case "🦷":
            return "mouth"
        case "🛁":
            return "drop.fill"
        case "🏥":
            return "cross.case.fill"
        case "😴":
            return "moon.fill"
        case "🌙":
            return "moon.stars.fill"
        case "🍽️":
            return "fork.knife"
        case "🍎":
            return "apple.logo"
        case "🚗":
            return "car.fill"
        case "🚌":
            return "bus.fill"
        case "📚":
            return "book.fill"
        case "📖":
            return "book.closed.fill"
        case "🎮":
            return "gamecontroller.fill"
        case "🏞️":
            return "tree.fill"
        case "🎨":
            return "paintbrush.fill"
        case "😭":
            return "face.smiling.inverse"
        case "😠":
            return "exclamationmark.triangle.fill"
        case "😊":
            return "face.smiling"
        case "😢":
            return "drop.triangle.fill"
        case "👥":
            return "person.2.fill"
        case "👨‍👩‍👧‍👦":
            return "house.fill"
        case "🧹":
            return "trash.fill"
        case "🙋‍♀️":
            return "hand.raised.fill"
        default:
            return "circle.fill"
        }
    }
    
    static func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return "Recent"
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return displayFormatter.string(from: date)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SituationCard(
            emoji: "🦷", 
            title: "Morning teeth brushing", 
            date: "Oct 15",
            isFavorited: false,
            onToggleFavorite: { print("Toggle favorite") },
            onDelete: { print("Delete card") }
        )
        SituationCard(
            emoji: "🛁", 
            title: "Bedtime meltdown", 
            date: "Oct 14",
            isFavorited: true,
            onToggleFavorite: { print("Toggle favorite") },
            onDelete: { print("Delete card") }
        )
        SituationCard(
            emoji: "🚗", 
            title: "School pickup", 
            date: "Oct 12",
            isFavorited: false,
            onToggleFavorite: { print("Toggle favorite") },
            onDelete: { print("Delete card") }
        )
        SituationCard(
            emoji: "🍽️", 
            title: "Dinner time", 
            date: "Oct 11",
            isFavorited: true,
            onToggleFavorite: { print("Toggle favorite") },
            onDelete: { print("Delete card") }
        )
    }
    .padding()
    .background(ColorPalette.navy)
}