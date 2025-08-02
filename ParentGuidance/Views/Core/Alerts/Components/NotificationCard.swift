import SwiftUI

struct NotificationCard: View {
    let content: String
    let onYesTryThis: () -> Void
    let onNotRightNow: () -> Void
    let onMaybeLater: () -> Void
    let onLearnMore: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
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
                    .fill(SemanticColors.accent)
                    .frame(width: 4)
                
                // Card content
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text(String(localized: "alerts.notification.title"))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    // Main content (variable)
                    Text(content)
                        .font(.system(size: 16))
                        .foregroundColor(SemanticColors.secondaryText)
                        .lineSpacing(2)
                    
                    // Disclaimer
                    Text(String(localized: "disclaimer.guidance.description"))
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.tertiaryText)
                        .lineSpacing(2)
                    
                    // Action buttons
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Button(action: onYesTryThis) {
                                Text(String(localized: "alerts.notification.accept"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SemanticColors.primaryText)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(SemanticColors.accent)
                                    .clipShape(Capsule())
                            }
                            
                            Button(action: onNotRightNow) {
                                Text(String(localized: "alerts.notification.dismiss"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SemanticColors.accent)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(SemanticColors.accent.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Button(action: onMaybeLater) {
                                Text(String(localized: "alerts.notification.postpone"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SemanticColors.accent)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(SemanticColors.accent.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            
                            Button(action: onLearnMore) {
                                Text(String(localized: "common.button.learnMore"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SemanticColors.accent)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(SemanticColors.accent.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(SemanticColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .if(colorScheme == .light) { view in
            view.cardShadow()
        }
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
    .background(SemanticColors.primaryBackground)
}