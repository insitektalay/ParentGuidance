import Foundation
import Supabase

// MARK: - Update Structs for Supabase
struct PlanUpdate: Encodable {
    let selectedPlan: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case selectedPlan = "selected_plan"
        case updatedAt = "updated_at"
    }
}

struct PlanSetupCompleteUpdate: Encodable {
    let planSetupComplete: Bool
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case planSetupComplete = "plan_setup_complete"
        case updatedAt = "updated_at"
    }
}

struct ApiKeyUpdate: Encodable {
    let userApiKey: String
    let apiKeyProvider: String
    let planSetupComplete: Bool
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case userApiKey = "user_api_key"
        case apiKeyProvider = "api_key_provider"
        case planSetupComplete = "plan_setup_complete"
        case updatedAt = "updated_at"
    }
}

struct ChildDetailsCompleteUpdate: Encodable {
    let childDetailsComplete: Bool
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case childDetailsComplete = "child_details_complete"
        case updatedAt = "updated_at"
    }
}

struct OnboardingCompleteUpdate: Encodable {
    let onboardingCompletedAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case onboardingCompletedAt = "onboarding_completed_at"
        case updatedAt = "updated_at"
    }
}

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @Published var currentProfile: UserProfile?
    @Published var familyChildren: [Child] = []
    @Published var isLoading = false
    
    private init() {}
    
    // MARK: - Profile Management
    
    func loadUserProfile(userId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: [UserProfile] = try await SupabaseManager.shared.client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            
            if let profile = response.first {
                await MainActor.run {
                    self.currentProfile = profile
                }
                
                // Also load children if profile exists
                try await loadFamilyChildren()
            }
        } catch {
            print("Error loading user profile: \(error.localizedDescription)")
            throw error
        }
    }
    
    func createUserProfile(userId: String, email: String) async throws {
        print("🔍 Creating profile for userId: \(userId), email: \(email)")
        
        // Add a delay to ensure the auth.users record is created
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Create profile without family_id first to avoid foreign key constraint
        let newProfile = UserProfile(
            id: userId,
            familyId: nil, // Set to nil to avoid foreign key constraint
            email: email,
            fullName: nil,
            role: "parent",
            selectedPlan: nil,
            planSetupComplete: false,
            childDetailsComplete: false,
            onboardingCompletedAt: nil,
            subscriptionStatus: nil,
            subscriptionId: nil,
            userApiKey: nil,
            apiKeyProvider: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        do {
            print("🔍 Attempting to create profile...")
            try await SupabaseManager.shared.client
                .from("profiles")
                .insert(newProfile)
                .execute()
            
            await MainActor.run {
                self.currentProfile = newProfile
            }
            print("✅ Profile created successfully")
        } catch {
            print("❌ Error creating user profile: \(error.localizedDescription)")
            print("❌ Full error: \(error)")
            
            if error.localizedDescription.contains("foreign key constraint") {
                print("🔧 Foreign key constraint issue detected.")
                print("🔧 This usually means the auth.users record hasn't been created yet.")
                print("🔧 Check your Supabase Auth settings - email confirmation might be required.")
            }
            
            throw error
        }
    }
    
    // MARK: - Onboarding Step Updates
    
    func updateSelectedPlan(_ plan: String) async throws {
        guard let profile = currentProfile else { return }
        
        do {
            try await SupabaseManager.shared.client
                .from("profiles")
                .update(PlanUpdate(selectedPlan: plan, updatedAt: ISO8601DateFormatter().string(from: Date())))
                .eq("id", value: profile.id)
                .execute()
            
            await MainActor.run {
                self.currentProfile = UserProfile(
                    id: profile.id,
                    familyId: profile.familyId,
                    email: profile.email,
                    fullName: profile.fullName,
                    role: profile.role,
                    selectedPlan: plan,
                    planSetupComplete: profile.planSetupComplete,
                    childDetailsComplete: profile.childDetailsComplete,
                    onboardingCompletedAt: profile.onboardingCompletedAt,
                    subscriptionStatus: profile.subscriptionStatus,
                    subscriptionId: profile.subscriptionId,
                    userApiKey: profile.userApiKey,
                    apiKeyProvider: profile.apiKeyProvider,
                    createdAt: profile.createdAt,
                    updatedAt: ISO8601DateFormatter().string(from: Date())
                )
            }
            
            print("✅ Plan updated to: \(plan)")
        } catch {
            print("Error updating plan: \(error.localizedDescription)")
            throw error
        }
    }
    
    func markPlanSetupComplete() async throws {
        guard let profile = currentProfile else { return }
        
        do {
            try await SupabaseManager.shared.client
                .from("profiles")
                .update(PlanSetupCompleteUpdate(planSetupComplete: true, updatedAt: ISO8601DateFormatter().string(from: Date())))
                .eq("id", value: profile.id)
                .execute()
            
            await MainActor.run {
                self.currentProfile = UserProfile(
                    id: profile.id,
                    familyId: profile.familyId,
                    email: profile.email,
                    fullName: profile.fullName,
                    role: profile.role,
                    selectedPlan: profile.selectedPlan,
                    planSetupComplete: true,
                    childDetailsComplete: profile.childDetailsComplete,
                    onboardingCompletedAt: profile.onboardingCompletedAt,
                    subscriptionStatus: profile.subscriptionStatus,
                    subscriptionId: profile.subscriptionId,
                    userApiKey: profile.userApiKey,
                    apiKeyProvider: profile.apiKeyProvider,
                    createdAt: profile.createdAt,
                    updatedAt: ISO8601DateFormatter().string(from: Date())
                )
            }
            
            print("✅ Plan setup marked complete")
        } catch {
            print("Error marking plan setup complete: \(error.localizedDescription)")
            throw error
        }
    }
    
    func saveApiKey(_ apiKey: String, provider: String) async throws {
        guard let profile = currentProfile else { return }
        
        do {
            try await SupabaseManager.shared.client
                .from("profiles")
                .update(ApiKeyUpdate(
                    userApiKey: apiKey,
                    apiKeyProvider: provider,
                    planSetupComplete: true,
                    updatedAt: ISO8601DateFormatter().string(from: Date())
                ))
                .eq("id", value: profile.id)
                .execute()
            
            await MainActor.run {
                self.currentProfile = UserProfile(
                    id: profile.id,
                    familyId: profile.familyId,
                    email: profile.email,
                    fullName: profile.fullName,
                    role: profile.role,
                    selectedPlan: profile.selectedPlan,
                    planSetupComplete: true,
                    childDetailsComplete: profile.childDetailsComplete,
                    onboardingCompletedAt: profile.onboardingCompletedAt,
                    subscriptionStatus: profile.subscriptionStatus,
                    subscriptionId: profile.subscriptionId,
                    userApiKey: apiKey,
                    apiKeyProvider: provider,
                    createdAt: profile.createdAt,
                    updatedAt: ISO8601DateFormatter().string(from: Date())
                )
            }
            
            print("✅ API key saved for provider: \(provider)")
        } catch {
            print("Error saving API key: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Children Management
    
    func loadFamilyChildren() async throws {
        guard let profile = currentProfile, let familyId = profile.familyId else { return }
        
        do {
            let response: [Child] = try await SupabaseManager.shared.client
                .from("children")
                .select()
                .eq("family_id", value: familyId)
                .execute()
                .value
            
            await MainActor.run {
                self.familyChildren = response
            }
        } catch {
            print("Error loading family children: \(error.localizedDescription)")
            throw error
        }
    }
    
    func addChild(name: String, age: Int? = nil, pronouns: String? = nil) async throws {
        guard let profile = currentProfile, let familyId = profile.familyId else { return }
        
        let newChild = Child(familyId: familyId, name: name, age: age, pronouns: pronouns)
        
        do {
            try await SupabaseManager.shared.client
                .from("children")
                .insert(newChild)
                .execute()
            
            // Mark child details as complete
            try await markChildDetailsComplete()
            
            // Reload children
            try await loadFamilyChildren()
            
            print("✅ Child added: \(name)")
        } catch {
            print("Error adding child: \(error.localizedDescription)")
            throw error
        }
    }
    
    func markChildDetailsComplete() async throws {
        guard let profile = currentProfile else { return }
        
        do {
            try await SupabaseManager.shared.client
                .from("profiles")
                .update(ChildDetailsCompleteUpdate(childDetailsComplete: true, updatedAt: ISO8601DateFormatter().string(from: Date())))
                .eq("id", value: profile.id)
                .execute()
            
            await MainActor.run {
                self.currentProfile = UserProfile(
                    id: profile.id,
                    familyId: profile.familyId,
                    email: profile.email,
                    fullName: profile.fullName,
                    role: profile.role,
                    selectedPlan: profile.selectedPlan,
                    planSetupComplete: profile.planSetupComplete,
                    childDetailsComplete: true,
                    onboardingCompletedAt: profile.onboardingCompletedAt,
                    subscriptionStatus: profile.subscriptionStatus,
                    subscriptionId: profile.subscriptionId,
                    userApiKey: profile.userApiKey,
                    apiKeyProvider: profile.apiKeyProvider,
                    createdAt: profile.createdAt,
                    updatedAt: ISO8601DateFormatter().string(from: Date())
                )
            }
            
            print("✅ Child details marked complete")
        } catch {
            print("Error marking child details complete: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Onboarding Completion
    
    func completeOnboarding() async throws {
        guard let profile = currentProfile else { return }
        
        do {
            let completionDate = ISO8601DateFormatter().string(from: Date())
            
            try await SupabaseManager.shared.client
                .from("profiles")
                .update(OnboardingCompleteUpdate(
                    onboardingCompletedAt: completionDate,
                    updatedAt: completionDate
                ))
                .eq("id", value: profile.id)
                .execute()
            
            await MainActor.run {
                self.currentProfile = UserProfile(
                    id: profile.id,
                    familyId: profile.familyId,
                    email: profile.email,
                    fullName: profile.fullName,
                    role: profile.role,
                    selectedPlan: profile.selectedPlan,
                    planSetupComplete: profile.planSetupComplete,
                    childDetailsComplete: profile.childDetailsComplete,
                    onboardingCompletedAt: completionDate,
                    subscriptionStatus: profile.subscriptionStatus,
                    subscriptionId: profile.subscriptionId,
                    userApiKey: profile.userApiKey,
                    apiKeyProvider: profile.apiKeyProvider,
                    createdAt: profile.createdAt,
                    updatedAt: completionDate
                )
            }
            
            print("🎉 Onboarding completed!")
        } catch {
            print("Error completing onboarding: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    func getFirstChildName() -> String {
        return familyChildren.first?.name ?? "Alex"
    }
    
    func checkOnboardingStatus() -> (isComplete: Bool, nextStep: OnboardingStep?) {
        guard let profile = currentProfile else {
            return (false, .welcome)
        }
        
        if profile.isOnboardingComplete {
            return (true, nil)
        }
        
        if profile.selectedPlan == nil {
            return (false, .plan)
        }
        
        if profile.needsPayment {
            return (false, .payment)
        }
        
        if profile.needsApiKey {
            return (false, .apiKey)
        }
        
        if !profile.childDetailsComplete {
            return (false, .child)
        }
        
        return (true, nil)
    }
}