import SwiftUI

struct RoutineCard: View {
    let time: String
    let activity: String
    let icon: String?
    
    init(time: String, activity: String, icon: String? = nil) {
        self.time = time
        self.activity = activity
        self.icon = icon
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Time label
            Text(time)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.6))
            
            // Activity card with navigation
            NavigationLink(destination: SituationGuidanceView()) {
                HStack(alignment: .center, spacing: 12) {
                    // Icon (if provided)
                    if let iconName = icon {
                        Image(systemName: iconName)
                            .font(.system(size: 20))
                            .foregroundColor(ColorPalette.white.opacity(0.7))
                            .frame(width: 20, height: 20)
                    }
                    
                    // Activity text
                    Text(activity)
                        .font(.system(size: 18))
                        .foregroundColor(ColorPalette.white)
                    
                    Spacer()
                }
                .padding(16)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ColorPalette.terracotta.opacity(0.3), lineWidth: 1)
                )
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
    .background(ColorPalette.navy)
}