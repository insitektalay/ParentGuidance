import Foundation

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