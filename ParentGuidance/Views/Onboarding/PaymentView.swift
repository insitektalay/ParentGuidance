import SwiftUI

struct PlanDetailsCard: View {
    let planTitle: String
    let benefits: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(planTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ColorPalette.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ColorPalette.white.opacity(0.9))
                        
                        Text(benefit)
                            .font(.system(size: 16))
                            .foregroundColor(ColorPalette.white.opacity(0.9))
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: "1F2132"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct PaymentView: View {
    let planTitle: String
    let monthlyPrice: String
    let benefits: [String]
    let onPayment: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    Text("Complete Your Purchase")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ColorPalette.white)
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
                            Text("Total: \(monthlyPrice)/month")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(ColorPalette.white)
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
                            .foregroundColor(ColorPalette.white)
                        
                        Text("Pay")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ColorPalette.white)
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
                
                Text("Cancel anytime")
                    .font(.system(size: 12))
                    .foregroundColor(ColorPalette.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
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
