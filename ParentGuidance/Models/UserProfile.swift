//
//  UserProfile.swift
//  ParentGuidance
//
//  Created by alex kerss on 06/07/2025.
//

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