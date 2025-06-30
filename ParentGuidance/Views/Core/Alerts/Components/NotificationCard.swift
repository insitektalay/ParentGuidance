import SwiftUI

struct NotificationCard: View {
    let content: String
    let onYesTryThis: () -> Void
    let onNotRightNow: () -> Void
    let onMaybeLater: () -> Void
    let onLearnMore: () -> Void
    
    init(
        content: String = "Based on the situations you've shared, some parents find the Zones of Regulation framework helpful for understanding intense emotional reactions and helping kids return to a calm state.",
        onYesTryThis: @escaping () -> Void = {},
        onNotRightNow: @escaping () -> Void = {},
        onMaybeLater: @escaping () -> Void = {},
        onLearnMore: @escaping () -> Void = {}
    ) {
        self.content = content
        self.onYesTryThis = onYesTryThis
        self.onNotRightNow = onNotRightNow
        self.onMaybeLater = onMaybeLater
        self.onLearnMore = onLearnMore
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                // Left terracotta border
                Rectangle()
                    .fill(ColorPalette.terracotta)
                    .frame(width: 4)
                
                // Card content
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text("You might find this helpful")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ColorPalette.navy)
                    
                    // Main content (variable)
                    Text(content)
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.navy.opacity(0.8))
                        .lineSpacing(2)
                    
                    // Disclaimer
                    Text("This isn't a diagnosis — just a way to understand what might be happening and try some ideas that have worked for other families.")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.navy.opacity(0.6))
                        .lineSpacing(2)
                    
                    // Action buttons
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Button(action: onYesTryThis) {
                                Text("Yes, Try This")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ColorPalette.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(ColorPalette.terracotta)
                                    .clipShape(Capsule())
                            }
                            
                            Button(action: onNotRightNow) {
                                Text("Not Right Now")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ColorPalette.terracotta)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(ColorPalette.terracotta.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Button(action: onMaybeLater) {
                                Text("Maybe Later")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ColorPalette.terracotta)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(ColorPalette.terracotta.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            
                            Button(action: onLearnMore) {
                                Text("Learn More")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ColorPalette.terracotta)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(ColorPalette.terracotta.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(red: 0.97, green: 0.95, blue: 0.91)) // #F7F3E9 equivalent
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
}

#Preview {
    VStack {
        NotificationCard()
        
        NotificationCard(
            content: "We've noticed that Alex seems to benefit from advance warning before transitions. This pattern is common and there are strategies that can help make these moments smoother."
        )
    }
    .padding()
    .background(ColorPalette.navy)
}