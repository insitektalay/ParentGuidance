import SwiftUI

struct SituationCard: View {
    let emoji: String
    let title: String
    let date: String
    let onTap: () -> Void
    
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