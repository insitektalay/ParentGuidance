//
//  SettingsFormatterService.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import Foundation
import SwiftUI

/// Service responsible for formatting display text in settings
class SettingsFormatterService {
    static let shared = SettingsFormatterService()
    
    private init() {}
    
    // MARK: - Child Age Formatting
    
    func formatChildAge(_ child: Child?) -> String {
        guard let child = child, let age = child.age else {
            return "Not set"
        }
        
        // Handle edge cases
        if age <= 0 {
            return "Not set"
        }
        
        // Format age consistently with onboarding pattern
        if age == 1 {
            return "1 year old"
        } else {
            return "\(age) years old"
        }
    }
    
    // MARK: - Email Text Formatting
    
    func formatEmailText(userProfile: UserProfile?, isLoading: Bool) -> String {
        if isLoading {
            return "Loading..."
        }
        return userProfile?.email ?? "Not available"
    }
    
    // MARK: - Plan Text Formatting
    
    func formatPlanText(userProfile: UserProfile?, isLoading: Bool) -> String {
        if isLoading {
            return "Loading..."
        }
        
        guard let plan = userProfile?.selectedPlan else {
            return "No plan selected"
        }
        
        switch plan.lowercased() {
        case "api":
            return "Bring Your Own API"
        case "basic":
            return "Basic Plan"
        case "premium":
            return "Premium Plan"
        case "family":
            return "Family Plan"
        default:
            return plan.capitalized
        }
    }
    
    // MARK: - API Key Status Formatting
    
    func formatApiKeyStatus(userProfile: UserProfile?, isLoading: Bool) -> String {
        if isLoading {
            return "Loading..."
        }
        
        guard let profile = userProfile else {
            return "Unknown"
        }
        
        if let apiKey = profile.userApiKey, !apiKey.isEmpty {
            return "Connected (\(profile.apiKeyProvider?.capitalized ?? "OpenAI"))"
        } else if profile.selectedPlan == "api" {
            return "Not configured"
        } else {
            return "Not required"
        }
    }
    
    // MARK: - Language Text Formatting
    
    func formatLanguageText(userProfile: UserProfile?, isLoading: Bool) -> String {
        if isLoading {
            return "Loading..."
        }
        
        let languageCode = userProfile?.preferredLanguage ?? "en"
        return LanguageDetectionService.shared.getLanguageName(for: languageCode)
    }
}
