//
//  ParentGuidanceApp.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/06/2025.
//

import SwiftUI

@main
struct ParentGuidanceApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                OnboardingFlow()
            }
        }
    }
}

struct OnboardingFlow: View {
    @State private var currentView: OnboardingStep = .welcome
    @State private var isLoadingProfile = false
    // @StateObject private var onboardingManager = OnboardingManager.shared
    
    enum OnboardingStep {
        case welcome
        case authentication
        case loading
        case plan
        case payment
        case apiKey
        case child
        case main
    }
    
    var body: some View {
        switch currentView {
        case .welcome:
            WelcomeView(
                onGetStarted: {
                    currentView = .authentication
                }
            )
        case .authentication:
            AuthenticationView(
                onAppleSignIn: {
                    currentView = .main
                },
                onGoogleSignIn: {
                    currentView = .main
                },
                onFacebookSignIn: {
                    currentView = .main
                },
                onEmailSignIn: { userId, email in
                    handleAuthentication(userId: userId, email: email)
                },
                onBackTapped: {
                    currentView = .welcome
                }
            )
        case .loading:
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Loading your profile...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        case .plan:
            PlanSelectionView(
                onBringOwnAPI: {
                    savePlanSelection("api", nextStep: .apiKey)
                },
                onStarterPlan: {
                    savePlanSelection("starter", nextStep: .payment)
                },
                onFamilyPlan: {
                    savePlanSelection("family", nextStep: .payment)
                },
                onPremiumPlan: {
                    savePlanSelection("premium", nextStep: .payment)
                }
            )
        case .payment:
            PaymentView(
                planTitle: "Selected Plan – £5/month",
                monthlyPrice: "£5.00",
                benefits: [
                    "Up to 5 family members",
                    "Premium features",
                    "Priority support"
                ],
                onPayment: {
                    currentView = .main
                }
            )
        case .apiKey:
            APIKeyView(
                onTestConnection: { apiKey in
                    print("🧪 Testing API key: \(apiKey)")
                },
                onSaveAndContinue: { apiKey in
                    saveApiKey(apiKey)
                },
                onGetAPIKey: {},
                onWhatsThis: {}
            )
        case .child:
            ChildBasicsView(
                onAddAnotherChild: { name, birthDate in
                    saveChildDetails(name: name, birthDate: birthDate, isAdditional: true)
                },
                onContinue: { name, birthDate in
                    saveChildDetails(name: name, birthDate: birthDate, isAdditional: false)
                }
            )
        case .main:
            MainTabView()
        }
    }
    
    private func handleAuthentication(userId: String, email: String?) {
        currentView = .loading
        
        Task {
            print("🎯 Authenticated user ID: \(userId)")
            print("🎯 User email: \(email ?? "No email")")
            
            // Simulate loading profile
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                print("📋 Starting onboarding from plan selection")
                currentView = .plan
            }
        }
    }
    
    private func savePlanSelection(_ plan: String, nextStep: OnboardingStep) {
        Task {
            print("💾 Saving plan selection: \(plan) to database...")
            
            // Simulate database save operation
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                print("✅ Plan saved successfully: \(plan)")
                currentView = nextStep
            }
        }
    }
    
    private func saveApiKey(_ apiKey: String) {
        Task {
            print("🔑 Saving API key: \(apiKey.prefix(10))... to database...")
            
            // Simulate database save operation
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                print("✅ API key saved successfully")
                currentView = .child
            }
        }
    }
    
    private func saveChildDetails(name: String, birthDate: Date, isAdditional: Bool) {
        Task {
            let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
            print("👶 Saving child details to database...")
            print("   Name: \(name)")
            print("   Age: \(age) years old")
            print("   Birth Date: \(DateFormatter.localizedString(from: birthDate, dateStyle: .medium, timeStyle: .none))")
            
            // Simulate database save operation
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                print("✅ Child details saved successfully")
                
                if isAdditional {
                    print("🔄 Ready to add another child")
                    // Stay on child details screen for additional child
                } else {
                    print("🎉 Onboarding complete! Navigating to main app")
                    currentView = .main
                }
            }
        }
    }
}

