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
    let step: OnboardingStep
    @State private var isLoadingProfile = false
    @StateObject private var authService = AuthService.shared
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    init(step: OnboardingStep) {
        self.step = step
    }
    
    
    var body: some View {
        switch step {
        case .welcome:
            WelcomeView(
                onGetStarted: {
                    appCoordinator.handleOnboardingStepComplete(.welcome)
                }
            )
        case .auth:
            AuthenticationView(
                onAppleSignIn: {
                    // TODO: Implement Apple sign in
                },
                onGoogleSignIn: {
                    // TODO: Implement Google sign in
                },
                onFacebookSignIn: {
                    // TODO: Implement Facebook sign in
                },
                onEmailSignIn: { userId, email in
                    // Notify AppCoordinator of successful authentication
                    Task {
                        await appCoordinator.handleSuccessfulAuthentication(userId: userId, email: email)
                    }
                },
                onBackTapped: {
                    Task {
                        await MainActor.run {
                            appCoordinator.currentState = .onboarding(.welcome)
                        }
                    }
                }
            )
        case .familyChoice:
            FamilyChoiceView(
                onCreateFamily: {
                    Task {
                        await MainActor.run {
                            appCoordinator.currentState = .onboarding(.plan)
                        }
                    }
                },
                onJoinFamily: {
                    Task {
                        await MainActor.run {
                            appCoordinator.currentState = .onboarding(.joinFamily)
                        }
                    }
                },
                onBackTapped: {
                    Task {
                        await MainActor.run {
                            appCoordinator.currentState = .onboarding(.auth)
                        }
                    }
                }
            )
        case .joinFamily:
            JoinFamilyView(
                onSuccessfulJoin: { familyId in
                    Task {
                        await MainActor.run {
                            appCoordinator.currentState = .onboarding(.plan)
                        }
                    }
                },
                onBackTapped: {
                    Task {
                        await MainActor.run {
                            appCoordinator.currentState = .onboarding(.familyChoice)
                        }
                    }
                }
            )
        case .plan:
            PlanSelectionView(
                onBringOwnAPI: {
                    savePlanSelection("api")
                },
                onStarterPlan: {
                    savePlanSelection("starter")
                },
                onFamilyPlan: {
                    savePlanSelection("family")
                },
                onPremiumPlan: {
                    savePlanSelection("premium")
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
                    appCoordinator.handleOnboardingStepComplete(.payment)
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
        }
    }
    
    
    private func savePlanSelection(_ plan: String) {
        Task {
            do {
                print("💾 Saving plan selection: \(plan) to database...")
                guard let userId = appCoordinator.currentUserId else {
                    print("❌ No current user ID available for plan selection")
                    return
                }
                try await authService.updateSelectedPlan(plan, userId: userId)
                
                print("✅ Plan saved successfully to database: \(plan)")
                appCoordinator.handlePlanSelection(plan)
            } catch {
                print("❌ Error saving plan to database: \(error.localizedDescription)")
                // Still navigate even if save fails, assume "api" plan for now
                print("⚠️ Proceeding despite save error")
                appCoordinator.handlePlanSelection(plan)
            }
        }
    }
    
    private func saveApiKey(_ apiKey: String) {
        Task {
            do {
                print("🔑 Saving API key: \(apiKey.prefix(10))... to database...")
                guard let userId = appCoordinator.currentUserId else {
                    print("❌ No current user ID available for API key")
                    return
                }
                try await authService.saveApiKey(apiKey, userId: userId)
                
                print("✅ API key saved successfully to database")
                appCoordinator.handleOnboardingStepComplete(.apiKey)
            } catch {
                print("❌ Error saving API key to database: \(error.localizedDescription)")
                // Still navigate even if save fails
                print("⚠️ Proceeding despite save error")
                appCoordinator.handleOnboardingStepComplete(.apiKey)
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
                
                guard let userId = appCoordinator.currentUserId else {
                    print("❌ No current user ID available for child details")
                    return
                }
                try await authService.saveChildDetails(name: name, birthDate: birthDate, userId: userId)
                
                await MainActor.run {
                    print("✅ Child details saved successfully to database")
                    
                    if isAdditional {
                        print("🔄 Ready to add another child")
                        // Stay on child details screen for additional child
                    } else {
                        print("🎉 Child details complete! Notifying AppCoordinator")
                        // Call AppCoordinator to handle the completion
                        appCoordinator.handleOnboardingStepComplete(.child)
                    }
                }
            } catch {
                print("❌ Error saving child details to database: \(error.localizedDescription)")
                // Still navigate even if save fails
                await MainActor.run {
                    if isAdditional {
                        print("🔄 Ready to add another child (despite error)")
                    } else {
                        print("🎉 Child details complete! Notifying AppCoordinator (despite error)")
                        // Call AppCoordinator to handle the completion even if save failed
                        appCoordinator.handleOnboardingStepComplete(.child)
                    }
                }
            }
        }
    }
}

// MARK: - OnboardingManager Class

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
