import Foundation
import SwiftUI

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
        Task {
            // Check if user is authenticated
            if let user = await authService.getCurrentUser() {
                await handleAuthenticatedUser(userId: user.id.uuidString, email: user.email)
            } else {
                // No authenticated user, start with onboarding
                await MainActor.run {
                    self.currentState = .onboarding(.welcome)
                }
            }
        }
    }
    
    func handleSuccessfulAuthentication(userId: String, email: String?) async {
        print("🔍 Authentication successful!")
        print("🔍 User ID: \(userId)")
        print("🔍 Email: \(email ?? "nil")")
        print("🔍 Expected existing user ID: 15359b56-cabf-4b6a-9d2a-a3b11001b8e2")
        print("🔍 IDs match? \(userId.lowercased() == "15359b56-cabf-4b6a-9d2a-a3b11001b8e2")")
        
        await MainActor.run {
            self.currentUserId = userId
        }
        
        await handleAuthenticatedUser(userId: userId, email: email)
    }
    
    private func handleAuthenticatedUser(userId: String, email: String?) async {
        do {
            // Try to load existing user profile
            try await onboardingManager.loadUserProfile(userId: userId)
            
            if onboardingManager.currentProfile == nil && email != nil {
                // For now, skip profile creation and go directly to plan selection
                print("⚠️ Skipping profile creation due to database constraints")
                print("🚀 Proceeding directly to plan selection")
                
                await MainActor.run {
                    self.currentUserId = userId
                    self.currentState = .onboarding(.plan)
                }
                return
            }
            
            // Check onboarding status
            let status = onboardingManager.checkOnboardingStatus()
            
            await MainActor.run {
                if status.isComplete {
                    self.currentState = .mainApp
                } else if let nextStep = status.nextStep {
                    self.currentState = .onboarding(nextStep)
                } else {
                    // Fallback to plan selection
                    self.currentState = .onboarding(.plan)
                }
            }
            
        } catch {
            print("Error handling authenticated user: \(error.localizedDescription)")
            
            // If it's just a profile loading issue, proceed to plan selection anyway
            await MainActor.run {
                self.currentUserId = userId
                self.currentState = .onboarding(.plan)
            }
        }
    }
    
    // MARK: - Onboarding Progress Management
    
    func handleOnboardingStepComplete(_ step: OnboardingStep) {
        Task {
            do {
                switch step {
                case .welcome:
                    await MainActor.run {
                        self.currentState = .onboarding(.auth)
                    }
                    
                case .auth:
                    // Authentication completion is handled by handleSuccessfulAuthentication
                    break
                    
                case .plan:
                    // Plan selection completion is handled by the plan selection view
                    // Check what the next step should be
                    let status = onboardingManager.checkOnboardingStatus()
                    await MainActor.run {
                        if let nextStep = status.nextStep {
                            self.currentState = .onboarding(nextStep)
                        } else {
                            self.currentState = .mainApp
                        }
                    }
                    
                case .payment:
                    try await onboardingManager.markPlanSetupComplete()
                    await moveToNextStep()
                    
                case .apiKey:
                    // API key completion is handled by the API key view
                    await moveToNextStep()
                    
                case .child:
                    try await onboardingManager.completeOnboarding()
                    await MainActor.run {
                        self.currentState = .mainApp
                    }
                }
            } catch {
                print("Error handling onboarding step completion: \(error.localizedDescription)")
            }
        }
    }
    
    func handlePlanSelection(_ plan: String) {
        Task {
            do {
                try await onboardingManager.updateSelectedPlan(plan)
                await moveToNextStep()
            } catch {
                print("Error updating plan selection: \(error.localizedDescription)")
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