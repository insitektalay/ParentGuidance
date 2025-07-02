//
//  ParentGuidanceApp.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/06/2025.
//

import SwiftUI
import Supabase
import Foundation

// UserProfile model
struct UserProfile: Codable {
    let id: String
    let familyId: String?
    let email: String?
    let fullName: String?
    let role: String?
    let selectedPlan: String?
    let planSetupComplete: Bool
    let childDetailsComplete: Bool
    let onboardingCompletedAt: String?
    let subscriptionStatus: String?
    let subscriptionId: String?
    let userApiKey: String?
    let apiKeyProvider: String?
    let createdAt: String
    let updatedAt: String
    
    // Custom initializer to handle string/bool conversion
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        familyId = try container.decodeIfPresent(String.self, forKey: .familyId)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        selectedPlan = try container.decodeIfPresent(String.self, forKey: .selectedPlan)
        onboardingCompletedAt = try container.decodeIfPresent(String.self, forKey: .onboardingCompletedAt)
        subscriptionStatus = try container.decodeIfPresent(String.self, forKey: .subscriptionStatus)
        subscriptionId = try container.decodeIfPresent(String.self, forKey: .subscriptionId)
        userApiKey = try container.decodeIfPresent(String.self, forKey: .userApiKey)
        apiKeyProvider = try container.decodeIfPresent(String.self, forKey: .apiKeyProvider)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        
        // Handle boolean fields that might come as strings or booleans
        if let planSetupBool = try? container.decode(Bool.self, forKey: .planSetupComplete) {
            planSetupComplete = planSetupBool
        } else if let planSetupString = try? container.decode(String.self, forKey: .planSetupComplete) {
            planSetupComplete = planSetupString.lowercased() == "true"
        } else {
            planSetupComplete = false
        }
        
        if let childDetailsBool = try? container.decode(Bool.self, forKey: .childDetailsComplete) {
            childDetailsComplete = childDetailsBool
        } else if let childDetailsString = try? container.decode(String.self, forKey: .childDetailsComplete) {
            childDetailsComplete = childDetailsString.lowercased() == "true"
        } else {
            childDetailsComplete = false
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case email
        case fullName = "full_name"
        case role
        case selectedPlan = "selected_plan"
        case planSetupComplete = "plan_setup_complete"
        case childDetailsComplete = "child_details_complete"
        case onboardingCompletedAt = "onboarding_completed_at"
        case subscriptionStatus = "subscription_status"
        case subscriptionId = "subscription_id"
        case userApiKey = "user_api_key"
        case apiKeyProvider = "api_key_provider"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var isOnboardingComplete: Bool {
        return selectedPlan != nil && planSetupComplete && childDetailsComplete
    }
    
    var needsPayment: Bool {
        return selectedPlan != nil && selectedPlan != "api" && !planSetupComplete
    }
    
    var needsApiKey: Bool {
        return selectedPlan == "api" && !planSetupComplete
    }
}

// Type aliases for compatibility
typealias Profile = UserProfile

// Simplified local OnboardingManager for database operations
class SimpleOnboardingManager: ObservableObject {
    static let shared = SimpleOnboardingManager()
    private init() {}
    
    func loadUserProfile(userId: String) async throws -> UserProfile {
        let supabase = SupabaseManager.shared.client
        let response: [UserProfile] = try await supabase
            .from("profiles")
            .select("*")
            .eq("id", value: userId)
            .execute()
            .value
        
        guard let profile = response.first else {
            throw NSError(domain: "ProfileNotFound", code: 404)
        }
        
        return profile
    }
    
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
                "api_key_provider": "openai",
                "plan_setup_complete": "true"
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
            .update(["child_details_complete": "true"])
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
            
            do {
                // Load user profile to check onboarding state
                let profile = try await SimpleOnboardingManager.shared.loadUserProfile(userId: userId)
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

