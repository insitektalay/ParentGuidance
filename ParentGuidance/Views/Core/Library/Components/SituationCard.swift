import SwiftUI

struct SituationCard: View {
    let emoji: String
    let title: String
    let date: String
    let onTap: () -> Void
    
    // Legacy initializer for backward compatibility
    init(
        emoji: String,
        title: String,
        date: String,
        onTap: @escaping () -> Void = {}
    ) {
        self.emoji = emoji
        self.title = title
        self.date = date
        self.onTap = onTap
    }
    
    // New initializer for Situation models
    init(
        situation: Situation,
        onTap: @escaping () -> Void = {}
    ) {
        self.emoji = Self.getEmojiForSituation(situation)
        self.title = situation.title
        self.date = Self.formatDate(situation.createdAt)
        self.onTap = onTap
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
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
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
            }
            .padding(12)
            .background(Color(red: 0.21, green: 0.22, blue: 0.33)) // #363853 equivalent
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
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
        SituationCard(emoji: "🦷", title: "Morning teeth brushing", date: "Oct 15")
        SituationCard(emoji: "🛁", title: "Bedtime meltdown", date: "Oct 14")
        SituationCard(emoji: "🚗", title: "School pickup", date: "Oct 12")
        SituationCard(emoji: "🍽️", title: "Dinner time", date: "Oct 11")
    }
    .padding()
    .background(ColorPalette.navy)
}