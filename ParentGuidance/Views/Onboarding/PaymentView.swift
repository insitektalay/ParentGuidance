import SwiftUI

struct PlanDetailsCard: View {
    let planTitle: String
    let benefits: [String]
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(planTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(SemanticColors.primaryText)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SemanticColors.secondaryText)
                        
                        Text(benefit)
                            .font(.system(size: 16))
                            .foregroundColor(SemanticColors.secondaryText)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(SemanticColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SemanticColors.tertiaryText.opacity(0.3), lineWidth: 1)
        )
        .if(colorScheme == .light) { view in view.cardShadow() }
    }
}

struct PaymentView: View {
    let planTitle: String
    let monthlyPrice: String
    let benefits: [String]
    let onPayment: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    Text(String(localized: "payment.title"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(SemanticColors.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 80)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 24) {
                        PlanDetailsCard(
                            planTitle: planTitle,
                            benefits: benefits
                        )
                        
                        HStack {
                            Spacer()
                            Text(String(localized: "payment.total \(monthlyPrice)"))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(SemanticColors.primaryText)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 150)
                }
            }
            
            VStack(spacing: 16) {
                Button(action: onPayment) {
                    HStack(spacing: 8) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 20))
                            .foregroundColor(SemanticColors.primaryText)
                        
                        Text(String(localized: "payment.payButton"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SemanticColors.primaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.black, Color(hex: "1a1a1a")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Text(String(localized: "payment.cancelAnytime"))
                    .font(.system(size: 12))
                    .foregroundColor(SemanticColors.tertiaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SemanticColors.primaryBackground)
        .ignoresSafeArea()
    }
}

#Preview {
    PaymentView(
        planTitle: "Family Plan – £5/month",
        monthlyPrice: "£5.00",
        benefits: [
            "Up to 5 family members",
            "Premium features",
            "Priority support"
        ],
        onPayment: {}
    )
}
