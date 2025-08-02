import SwiftUI

struct PlanCard: View {
    let icon: String
    let title: String
    let description: String
    let price: String?
    let buttonText: String
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SemanticColors.accent.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(SemanticColors.accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SemanticColors.primaryText)
                        
                        Spacer()
                        
                        if let price = price {
                            Text(price)
                                .font(.system(size: 14))
                                .foregroundColor(SemanticColors.tertiaryText)
                        }
                    }
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.tertiaryText)
                }
            }
            .padding(.bottom, 12)
            
            Button(action: action) {
                Text(buttonText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SemanticColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(SemanticColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(SemanticColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SemanticColors.accent.opacity(0.2), lineWidth: 1)
        )
        .if(colorScheme == .light) { view in view.cardShadow() }
    }
}

struct PlanSelectionView: View {
    let onBringOwnAPI: () -> Void
    let onStarterPlan: () -> Void
    let onFamilyPlan: () -> Void
    let onPremiumPlan: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(String(localized: "planSelection.title"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(String(localized: "planSelection.subtitle"))
                    .font(.body)
                    .foregroundColor(SemanticColors.tertiaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 80)
            .padding(.horizontal, 16)
            
            ScrollView {
                VStack(spacing: 12) {
                    PlanCard(
                        icon: "gearshape",
                        title: String(localized: "planSelection.bringOwnAPI.title"),
                        description: String(localized: "planSelection.bringOwnAPI.description"),
                        price: nil,
                        buttonText: String(localized: "planSelection.bringOwnAPI.button"),
                        action: onBringOwnAPI
                    )
                    
                    PlanCard(
                        icon: "star",
                        title: String(localized: "planSelection.starter.title"),
                        description: String(localized: "planSelection.starter.description"),
                        price: String(localized: "planSelection.starter.price"),
                        buttonText: String(localized: "planSelection.starter.button"),
                        action: onStarterPlan
                    )
                    
                    PlanCard(
                        icon: "person.2",
                        title: String(localized: "planSelection.family.title"),
                        description: String(localized: "planSelection.family.description"),
                        price: String(localized: "planSelection.family.price"),
                        buttonText: String(localized: "planSelection.family.button"),
                        action: onFamilyPlan
                    )
                    
                    PlanCard(
                        icon: "diamond",
                        title: String(localized: "planSelection.premium.title"),
                        description: String(localized: "planSelection.premium.description"),
                        price: String(localized: "planSelection.premium.price"),
                        buttonText: String(localized: "planSelection.premium.button"),
                        action: onPremiumPlan
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SemanticColors.primaryBackground)
        .ignoresSafeArea()
    }
}

#Preview {
    PlanSelectionView(
        onBringOwnAPI: {},
        onStarterPlan: {},
        onFamilyPlan: {},
        onPremiumPlan: {}
    )
}
