import SwiftUI

struct RoutineCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let time: String
    let activity: String
    let icon: String?
    let situation: Situation?
    
    // Legacy initializer for compatibility
    init(time: String, activity: String, icon: String? = nil) {
        self.time = time
        self.activity = activity
        self.icon = icon
        self.situation = nil
    }
    
    // New initializer that accepts Situation object
    init(situation: Situation, time: String, icon: String) {
        self.time = time
        self.activity = situation.title
        self.icon = icon
        self.situation = situation
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Time label
            Text(time)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.tertiaryText)
            
            // Activity card with navigation
            NavigationLink(destination: SituationGuidanceView(situation: situation)) {
                HStack(alignment: .center, spacing: 12) {
                    // Icon (if provided)
                    if let iconName = icon {
                        Image(systemName: iconName)
                            .font(.system(size: 20))
                            .foregroundColor(SemanticColors.secondaryText)
                            .frame(width: 20, height: 20)
                    }
                    
                    // Activity text
                    Text(activity)
                        .font(.system(size: 18))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Spacer()
                }
                .padding(16)
                .background(SemanticColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(SemanticColors.accent.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .modifier(ConditionalCardShadow(colorScheme: colorScheme))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.bottom, 24)
    }
}

#Preview {
    VStack {
        RoutineCard(time: "7:55 AM", activity: "Morning Teeth Brushing")
        RoutineCard(time: "8:05 AM", activity: "Drive to School", icon: "car")
        RoutineCard(time: "6:00 PM", activity: "Dinner Time", icon: "fork.knife")
    }
    .padding()
    .background(SemanticColors.primaryBackground)
}

// MARK: - Conditional Shadow Modifier for Cards
struct ConditionalCardShadow: ViewModifier {
    let colorScheme: ColorScheme
    
    func body(content: Content) -> some View {
        if colorScheme == .light {
            content.cardShadow()
        } else {
            content
        }
    }
}