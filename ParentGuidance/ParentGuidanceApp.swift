//
//  ParentGuidanceApp.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/06/2025.
//

import SwiftUI
import Supabase

// Simplified local OnboardingManager for database operations
class SimpleOnboardingManager: ObservableObject {
    static let shared = SimpleOnboardingManager()
    private init() {}
    
    func updateSelectedPlan(_ plan: String, userId: String) async throws {
        let supabase = SupabaseManager.shared.client
        try await supabase
            .from("profiles")
            .update(["selected_plan": plan])
            .eq("id", value: userId)
            .execute()
    }
    
    func saveApiKey(_ apiKey: String, userId: String) async throws {
        let supabase = SupabaseManager.shared.client
        try await supabase
            .from("profiles")
            .update([
                "user_api_key": apiKey,
                "api_key_provider": "openai"
            ])
            .eq("id", value: userId)
            .execute()
    }
    
    func saveChildDetails(name: String, birthDate: Date, userId: String) async throws {
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        let supabase = SupabaseManager.shared.client
        
        // For now, we'll just update the profile to mark child details complete
        try await supabase
            .from("profiles")
            .update(["child_details_complete": true])
            .eq("id", value: userId)
            .execute()
        
        // TODO: Create actual child record when we resolve the family_id issue
        print("Child details: \(name), age: \(age)")
    }
}

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
    @State private var currentUserId: String = ""
    @StateObject private var onboardingManager = SimpleOnboardingManager.shared
    
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
        currentUserId = userId
        
        Task {
            print("🎯 Authenticated user ID: \(userId)")
            print("🎯 User email: \(email ?? "No email")")
            
            // Simulate loading profile (will add real profile loading later)
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                print("📋 Starting onboarding from plan selection")
                currentView = .plan
            }
        }
    }
    
    private func savePlanSelection(_ plan: String, nextStep: OnboardingStep) {
        Task {
            do {
                print("💾 Saving plan selection: \(plan) to database...")
                try await onboardingManager.updateSelectedPlan(plan, userId: currentUserId)
                
                await MainActor.run {
                    print("✅ Plan saved successfully to database: \(plan)")
                    currentView = nextStep
                }
            } catch {
                print("❌ Error saving plan to database: \(error.localizedDescription)")
                // Still navigate even if save fails
                await MainActor.run {
                    print("⚠️ Proceeding despite save error")
                    currentView = nextStep
                }
            }
        }
    }
    
    private func saveApiKey(_ apiKey: String) {
        Task {
            do {
                print("🔑 Saving API key: \(apiKey.prefix(10))... to database...")
                try await onboardingManager.saveApiKey(apiKey, userId: currentUserId)
                
                await MainActor.run {
                    print("✅ API key saved successfully to database")
                    currentView = .child
                }
            } catch {
                print("❌ Error saving API key to database: \(error.localizedDescription)")
                // Still navigate even if save fails
                await MainActor.run {
                    print("⚠️ Proceeding despite save error")
                    currentView = .child
                }
            }
        }
    }
    
    private func saveChildDetails(name: String, birthDate: Date, isAdditional: Bool) {
        Task {
            do {
                let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
                print("👶 Saving child details to database...")
                print("   Name: \(name)")
                print("   Age: \(age) years old")
                print("   Birth Date: \(DateFormatter.localizedString(from: birthDate, dateStyle: .medium, timeStyle: .none))")
                
                try await onboardingManager.saveChildDetails(name: name, birthDate: birthDate, userId: currentUserId)
                
                await MainActor.run {
                    print("✅ Child details saved successfully to database")
                    
                    if isAdditional {
                        print("🔄 Ready to add another child")
                        // Stay on child details screen for additional child
                    } else {
                        print("🎉 Onboarding complete! Navigating to main app")
                        currentView = .main
                    }
                }
            } catch {
                print("❌ Error saving child details to database: \(error.localizedDescription)")
                // Still navigate even if save fails
                await MainActor.run {
                    if isAdditional {
                        print("🔄 Ready to add another child (despite error)")
                    } else {
                        print("🎉 Onboarding complete! Navigating to main app (despite error)")
                        currentView = .main
                    }
                }
            }
        }
    }
}

