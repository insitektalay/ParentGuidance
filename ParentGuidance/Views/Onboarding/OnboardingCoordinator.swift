//
//  OnboardingCoordinator.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/06/2025.
//

import SwiftUI

enum OnboardingStep {
    case welcome
    case auth
    case plan
    case payment
    case apiKey
    case child
}

struct OnboardingCoordinator: View {
    @State private var step: OnboardingStep = .welcome
    @State private var selectedPlan: String? = nil

    var body: some View {
        switch step {
        case .welcome:
            WelcomeView(onGetStarted: {
                step = .auth
            })

        case .auth:
            AuthenticationView(
                onAppleSignIn: { step = .plan },
                onGoogleSignIn: { step = .plan },
                onFacebookSignIn: { step = .plan },
                onEmailSignIn: { _, _ in step = .plan },
                onBackTapped: { step = .welcome }
            )

        case .plan:
            PlanSelectionView(
                onBringOwnAPI: {
                    selectedPlan = "api"
                    step = .apiKey
                },
                onStarterPlan: {
                    selectedPlan = "starter"
                    step = .payment
                },
                onFamilyPlan: {
                    selectedPlan = "family"
                    step = .payment
                },
                onPremiumPlan: {
                    selectedPlan = "premium"
                    step = .payment
                }
            )

        case .payment:
            PaymentView(
                planTitle: "\(selectedPlan?.capitalized ?? "") Plan – £5/month",
                monthlyPrice: "£5.00",
                benefits: [
                    "Up to 5 family members",
                    "Premium features",
                    "Priority support"
                ],
                onPayment: {
                    step = .child
                }
            )

        case .apiKey:
            APIKeyView(
                onTestConnection: { _ in },
                onSaveAndContinue: { _ in
                    step = .child
                },
                onGetAPIKey: {},
                onWhatsThis: {}
            )

        case .child:
            ChildBasicsView(
                onAddAnotherChild: { _, _ in },
                onContinue: { _, _ in
                    print("✅ Onboarding complete — transition to ContentView()")
                }
            )
        }
    }
}
