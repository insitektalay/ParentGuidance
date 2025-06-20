import SwiftUI

struct PlanCard: View {
    let icon: String
    let title: String
    let description: String
    let price: String?
    let buttonText: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ColorPalette.terracotta.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(ColorPalette.terracotta)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ColorPalette.white)
                        
                        Spacer()
                        
                        if let price = price {
                            Text(price)
                                .font(.system(size: 14))
                                .foregroundColor(ColorPalette.white.opacity(0.6))
                        }
                    }
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                }
            }
            .padding(.bottom, 12)
            
            Button(action: action) {
                Text(buttonText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorPalette.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(ColorPalette.terracotta)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color(hex: "363853"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.terracotta.opacity(0.2), lineWidth: 1)
        )
    }
}

struct PlanSelectionView: View {
    let onBringOwnAPI: () -> Void
    let onStarterPlan: () -> Void
    let onFamilyPlan: () -> Void
    let onPremiumPlan: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("You're ready to start!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorPalette.white)
                    .multilineTextAlignment(.center)
                
                Text("Choose your plan to continue")
                    .font(.body)
                    .foregroundColor(ColorPalette.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 80)
            .padding(.horizontal, 16)
            
            ScrollView {
                VStack(spacing: 12) {
                    PlanCard(
                        icon: "gearshape",
                        title: "Bring Your Own API",
                        description: "Full control & functionality",
                        price: nil,
                        buttonText: "Use My API Key",
                        action: onBringOwnAPI
                    )
                    
                    PlanCard(
                        icon: "star",
                        title: "Starter Plan",
                        description: "Occasional use",
                        price: "£3/month",
                        buttonText: "Choose Starter Plan",
                        action: onStarterPlan
                    )
                    
                    PlanCard(
                        icon: "person.2",
                        title: "Family Plan",
                        description: "Multiple children support",
                        price: "£5/month",
                        buttonText: "Choose Family Plan",
                        action: onFamilyPlan
                    )
                    
                    PlanCard(
                        icon: "diamond",
                        title: "Premium Plan",
                        description: "Priority processing",
                        price: "£10/month",
                        buttonText: "Choose Premium Plan",
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
        .background(ColorPalette.navy)
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
