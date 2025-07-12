import Foundation
import SwiftUI
import Combine

enum AppState {
    case loading
    case onboarding(OnboardingStep)
    case mainApp
}

class AppCoordinator: ObservableObject {
    @Published var currentState: AppState = .loading
    @Published var currentUserId: String?
    
    private let onboardingManager = OnboardingManager.shared
    private let authService = AuthService.shared
    
    init() {
        checkAuthenticationState()
    }
    
    // MARK: - Authentication State Management
    
    func checkAuthenticationState() {
        print("🚀 App launched - checking authentication state...")
        Task {
            // Check if user is authenticated
            if let user = await authService.getCurrentUser() {
                print("👤 Found authenticated user: \(user.email ?? "no email") (ID: \(user.id.uuidString))")
                await handleAuthenticatedUser(userId: user.id.uuidString, email: user.email)
            } else {
                print("👤 No authenticated user found")
                print("🎯 Routing decision: Starting with welcome screen")
                // No authenticated user, start with onboarding
                await MainActor.run {
                    self.currentState = .onboarding(.welcome)
                }
            }
        }
    }
    
    func handleSuccessfulAuthentication(userId: String, email: String?) async {
        print("🔐 'Continue with Email' clicked!")
        print("🔐 Authentication successful!")
        print("👤 Authenticated as: \(email ?? "no email") (ID: \(userId))")
        print("🔍 Expected existing user ID: 15359b56-cabf-4b6a-9d2a-a3b11001b8e2")
        print("🔍 IDs match? \(userId.lowercased() == "15359b56-cabf-4b6a-9d2a-a3b11001b8e2")")
        
        await MainActor.run {
            self.currentUserId = userId
        }
        
        await handleAuthenticatedUser(userId: userId, email: email)
    }
    
    private func handleAuthenticatedUser(userId: String, email: String?) async {
        print("📊 Loading user profile for: \(email ?? "no email") (ID: \(userId))")
        
        // Set the current user ID immediately
        await MainActor.run {
            self.currentUserId = userId
        }
        
        do {
            // Try to load existing user profile
            try await onboardingManager.loadUserProfile(userId: userId)
            
            if let profile = onboardingManager.currentProfile {
                print("📊 User profile loaded successfully:")
                print("   - Email: \(profile.email ?? "no email")")
                print("   - Selected Plan: \(profile.selectedPlan ?? "none")")
                print("   - Plan Setup Complete: \(profile.planSetupComplete)")
                print("   - Child Details Complete: \(profile.childDetailsComplete)")
                print("   - Onboarding Complete: \(profile.isOnboardingComplete)")
                
                // Load and display actual child data
                await loadAndDisplayChildData(userId: userId, profileComplete: profile.childDetailsComplete)
            } else {
                print("📊 No user profile found in database")
            }
            
            if onboardingManager.currentProfile == nil && email != nil {
                print("⚠️ Skipping profile creation due to database constraints")
                print("🎯 Routing decision: Going to plan selection")
                
                await MainActor.run {
                    self.currentUserId = userId
                    self.currentState = .onboarding(.plan)
                }
                return
            }
            
            // Check onboarding status
            let status = onboardingManager.checkOnboardingStatus()
            print("📊 Onboarding status check:")
            print("   - Is Complete: \(status.isComplete)")
            print("   - Next Step: \(String(describing: status.nextStep))")
            
            await MainActor.run {
                if status.isComplete {
                    print("🎯 Routing decision: Onboarding complete → Main App")
                    self.currentState = .mainApp
                } else if let nextStep = status.nextStep {
                    print("🎯 Routing decision: Onboarding incomplete → \(nextStep)")
                    self.currentState = .onboarding(nextStep)
                } else {
                    print("🎯 Routing decision: Fallback → Plan selection")
                    self.currentState = .onboarding(.plan)
                }
            }
            
        } catch {
            print("❌ Error loading user profile: \(error.localizedDescription)")
            print("🎯 Routing decision: Error fallback → Plan selection")
            
            // If it's just a profile loading issue, proceed to plan selection anyway
            await MainActor.run {
                self.currentUserId = userId
                self.currentState = .onboarding(.plan)
            }
        }
    }
    
    private func loadAndDisplayChildData(userId: String, profileComplete: Bool) async {
        do {
            let supabase = SupabaseManager.shared.client
            
            // Load children from database using family_id (which equals userId)
            let response: [Child] = try await supabase
                .from("children")
                .select("*")
                .eq("family_id", value: userId)
                .execute()
                .value
            
            if response.isEmpty {
                if profileComplete {
                    print("⚠️ Profile says children complete but no children found in database")
                    print("👶 Children in database: 0")
                } else {
                    print("👶 No children found (as expected, profile incomplete)")
                }
            } else {
                print("👶 Children found: \(response.count)")
                for (index, child) in response.enumerated() {
                    let createdDate = child.createdAt ?? "unknown"
                    print("👶 Child \(index + 1): \(child.name ?? "no name"), age \(child.age), created: \(createdDate)")
                }
                
                if !profileComplete {
                    print("⚠️ Children exist but profile says incomplete - potential data inconsistency")
                }
            }
            
        } catch {
            print("❌ Error loading child data: \(error.localizedDescription)")
            if profileComplete {
                print("⚠️ Profile says children complete but failed to load from database")
            }
        }
    }
    
    // MARK: - Onboarding Progress Management
    
    func handleOnboardingStepComplete(_ step: OnboardingStep) {
        print("🎯 Onboarding step completed: \(step)")
        Task {
            do {
                switch step {
                case .welcome:
                    print("🎯 Welcome completed → Auth screen")
                    await MainActor.run {
                        self.currentState = .onboarding(.auth)
                    }
                    
                case .auth:
                    print("🎯 Auth completed → Handled by handleSuccessfulAuthentication")
                    // Authentication completion is handled by handleSuccessfulAuthentication
                    break
                    
                case .plan:
                    print("🎯 Plan selection completed → Checking next step")
                    
                    // For plan selection, we can determine next step without profile
                    // since we just saved the plan selection
                    print("🎯 Determining next step based on plan selection")
                    
                    // Check what the next step should be
                    let status = onboardingManager.checkOnboardingStatus()
                    print("📊 Status after plan selection: isComplete=\(status.isComplete), nextStep=\(String(describing: status.nextStep))")
                    await MainActor.run {
                        if let nextStep = status.nextStep {
                            print("🎯 Plan completed → \(nextStep)")
                            self.currentState = .onboarding(nextStep)
                        } else {
                            print("🎯 Plan completed → Main App")
                            self.currentState = .mainApp
                        }
                    }
                    
                case .payment:
                    print("🎯 Payment completed → Marking plan setup complete")
                    try await onboardingManager.markPlanSetupComplete()
                    await moveToNextStep()
                    
                case .apiKey:
                    print("🎯 API Key completed → Moving to child details")
                    
                    // After API key is saved, go directly to child details
                    await MainActor.run {
                        self.currentState = .onboarding(.child)
                    }
                    
                case .child:
                    print("🎯 Child details completed → Completing onboarding")
                    
                    // Child details are complete, route directly to main app
                    // We'll handle the profile completion in the background
                    print("✅ Onboarding complete! Routing to Main App")
                    await MainActor.run {
                        print("🎯 Setting currentState to .mainApp")
                        self.currentState = .mainApp
                    }
                    
                    // Try to complete onboarding in the background (optional)
                    Task {
                        do {
                            if let userId = currentUserId {
                                try await onboardingManager.loadUserProfile(userId: userId)
                                if onboardingManager.currentProfile != nil {
                                    try await onboardingManager.completeOnboarding()
                                    print("✅ Onboarding marked as complete in background")
                                }
                            }
                        } catch {
                            print("⚠️ Background onboarding completion failed, but user is in main app")
                        }
                    }
                }
            } catch {
                print("❌ Error handling onboarding step completion: \(error.localizedDescription)")
                
                // If we fail to complete onboarding, try to route to main app anyway
                // This prevents users from getting permanently stuck
                if step == .child {
                    print("⚠️ Child step failed, but routing to main app anyway")
                    await MainActor.run {
                        self.currentState = .mainApp
                    }
                }
            }
        }
    }
    
    func handlePlanSelection(_ plan: String) {
        Task {
            print("📋 Plan selection: \(plan)")
            
            // Route based on plan selection
            await MainActor.run {
                if plan == "api" {
                    print("🎯 Plan: API → Routing to API Key screen")
                    self.currentState = .onboarding(.apiKey)
                } else {
                    print("🎯 Plan: \(plan) → Routing to Payment screen")
                    self.currentState = .onboarding(.payment)
                }
            }
        }
    }
    
    func handleApiKeySaved(_ apiKey: String, provider: String) {
        Task {
            do {
                try await onboardingManager.saveApiKey(apiKey, provider: provider)
                await moveToNextStep()
            } catch {
                print("Error saving API key: \(error.localizedDescription)")
            }
        }
    }
    
    func handleChildAdded(name: String, age: Int? = nil, pronouns: String? = nil) {
        Task {
            do {
                try await onboardingManager.addChild(name: name, age: age, pronouns: pronouns)
                await moveToNextStep()
            } catch {
                print("Error adding child: \(error.localizedDescription)")
            }
        }
    }
    
    private func moveToNextStep() async {
        let status = onboardingManager.checkOnboardingStatus()
        
        await MainActor.run {
            if status.isComplete {
                self.currentState = .mainApp
            } else if let nextStep = status.nextStep {
                self.currentState = .onboarding(nextStep)
            } else {
                self.currentState = .mainApp
            }
        }
    }
    
    // MARK: - Profile Management
    
    private func createUserProfile(userId: String) async throws {
        print("📊 Creating/updating user profile for user ID: \(userId)")
        
        let supabase = SupabaseManager.shared.client
        try await supabase
            .from("profiles")
            .upsert([
                "id": userId,
                "email": "",
                "plan_setup_complete": "false",
                "child_details_complete": "false",
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ])
            .execute()
        
        print("✅ User profile created/updated successfully")
    }
    
    // MARK: - Navigation Helpers
    
    func signOut() {
        Task {
            do {
                try await authService.signOut()
                
                await MainActor.run {
                    self.currentUserId = nil
                    self.currentState = .onboarding(.welcome)
                }
                
            } catch {
                print("Error signing out: \(error.localizedDescription)")
            }
        }
    }
    
    func restartOnboarding() {
        Task {
            await MainActor.run {
                self.currentState = .onboarding(.welcome)
            }
        }
    }
}