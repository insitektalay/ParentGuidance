//
//  OnboardingManager.swift
//  ParentGuidance
//
//  Created by alex kerss on 06/07/2025.
//

import SwiftUI
import Foundation
import Supabase

struct OnboardingFlow: View {
    @State private var currentView: OnboardingStep = .welcome
    @State private var isLoadingProfile = false
    @State private var currentUserId: String = ""
    @StateObject private var authService = AuthService.shared
    
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
            
            do {
                // Load user profile to check onboarding state
                let profile = try await AuthService.shared.loadUserProfile(userId: userId)
                print("👤 Loaded user profile: \(profile.email ?? "No email")")
                
                await MainActor.run {
                    print("🔍 Profile state:")
                    print("   selectedPlan: \(profile.selectedPlan ?? "nil")")
                    print("   planSetupComplete: \(profile.planSetupComplete)")
                    print("   childDetailsComplete: \(profile.childDetailsComplete)")
                    print("   isOnboardingComplete: \(profile.isOnboardingComplete)")
                    
                    if profile.isOnboardingComplete {
                        print("✅ Onboarding complete! Going to main app")
                        currentView = .main
                    } else if profile.selectedPlan == nil {
                        print("📋 No plan selected, starting from plan selection")
                        currentView = .plan
                    } else if profile.needsPayment {
                        print("💳 Plan selected but needs payment")
                        currentView = .payment
                    } else if profile.needsApiKey {
                        print("🔑 Plan selected but needs API key")
                        currentView = .apiKey
                    } else if !profile.childDetailsComplete {
                        print("👶 Plan and payment complete, needs child details")
                        currentView = .child
                    } else {
                        print("🎉 All steps complete, going to main app")
                        currentView = .main
                    }
                }
            } catch {
                print("❌ Error loading profile: \(error.localizedDescription)")
                // Fallback to plan selection if profile loading fails
                await MainActor.run {
                    print("⚠️ Fallback: Starting from plan selection")
                    currentView = .plan
                }
            }
        }
    }
    
    private func savePlanSelection(_ plan: String, nextStep: OnboardingStep) {
        Task {
            do {
                print("💾 Saving plan selection: \(plan) to database...")
                try await authService.updateSelectedPlan(plan, userId: currentUserId)
                
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
                try await authService.saveApiKey(apiKey, userId: currentUserId)
                
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
                
                try await authService.saveChildDetails(name: name, birthDate: birthDate, userId: currentUserId)
                
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

// MARK: - OnboardingManager Class

// Use the OnboardingStep enum from OnboardingCoordinator
struct OnboardingStatus {
    let isComplete: Bool
    let nextStep: OnboardingStep?
}

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @Published var currentProfile: UserProfile?
    private let authService = AuthService.shared
    
    private init() {}
    
    // MARK: - Profile Management
    
    func loadUserProfile(userId: String) async throws {
        let profile = try await authService.loadUserProfile(userId: userId)
        await MainActor.run {
            self.currentProfile = profile
        }
    }
    
    func checkOnboardingStatus() -> OnboardingStatus {
        guard let profile = currentProfile else {
            return OnboardingStatus(isComplete: false, nextStep: .plan)
        }
        
        if profile.isOnboardingComplete {
            return OnboardingStatus(isComplete: true, nextStep: nil)
        }
        
        // Determine next step based on current state
        if profile.selectedPlan == nil {
            return OnboardingStatus(isComplete: false, nextStep: .plan)
        } else if profile.needsPayment {
            return OnboardingStatus(isComplete: false, nextStep: .payment)
        } else if profile.needsApiKey {
            return OnboardingStatus(isComplete: false, nextStep: .apiKey)
        } else if !profile.childDetailsComplete {
            return OnboardingStatus(isComplete: false, nextStep: .child)
        } else {
            return OnboardingStatus(isComplete: true, nextStep: nil)
        }
    }
    
    // MARK: - Plan Management
    
    func updateSelectedPlan(_ plan: String) async throws {
        guard let userId = currentProfile?.id else {
            throw NSError(domain: "OnboardingManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "No user profile loaded"])
        }
        
        try await authService.updateSelectedPlan(plan, userId: userId)
        
        // Reload profile to get updated data
        try await loadUserProfile(userId: userId)
    }
    
    func markPlanSetupComplete() async throws {
        guard let userId = currentProfile?.id else {
            throw NSError(domain: "OnboardingManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "No user profile loaded"])
        }
        
        // Update the profile to mark plan setup complete
        let supabase = SupabaseManager.shared.client
        try await supabase
            .from("profiles")
            .update(["plan_setup_complete": true])
            .eq("id", value: userId)
            .execute()
        
        // Reload profile to get updated data
        try await loadUserProfile(userId: userId)
    }
    
    // MARK: - API Key Management
    
    func saveApiKey(_ apiKey: String, provider: String) async throws {
        guard let userId = currentProfile?.id else {
            throw NSError(domain: "OnboardingManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "No user profile loaded"])
        }
        
        try await authService.saveApiKey(apiKey, userId: userId)
        
        // Reload profile to get updated data
        try await loadUserProfile(userId: userId)
    }
    
    // MARK: - Child Management
    
    func addChild(name: String, age: Int? = nil, pronouns: String? = nil) async throws {
        guard let userId = currentProfile?.id else {
            throw NSError(domain: "OnboardingManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "No user profile loaded"])
        }
        
        // For now, we'll use a birthdate calculated from age if provided
        let birthDate = age != nil ? Calendar.current.date(byAdding: .year, value: -(age!), to: Date()) ?? Date() : Date()
        
        try await authService.saveChildDetails(name: name, birthDate: birthDate, userId: userId)
        
        // Reload profile to get updated data
        try await loadUserProfile(userId: userId)
    }
    
    // MARK: - Completion
    
    func completeOnboarding() async throws {
        guard let userId = currentProfile?.id else {
            throw NSError(domain: "OnboardingManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "No user profile loaded"])
        }
        
        let supabase = SupabaseManager.shared.client
        try await supabase
            .from("profiles")
            .update([
                "onboarding_completed_at": ISO8601DateFormatter().string(from: Date()),
                "child_details_complete": "true"
            ])
            .eq("id", value: userId)
            .execute()
        
        // Reload profile to get updated data
        try await loadUserProfile(userId: userId)
    }
}
