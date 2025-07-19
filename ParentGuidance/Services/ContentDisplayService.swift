//
//  ContentDisplayService.swift
//  ParentGuidance
//
//  Created by alex kerss on 19/07/2025.
//

import Foundation
import Combine

/// Central service for intelligent content display logic in multilingual families
class ContentDisplayService: ObservableObject {
    static let shared = ContentDisplayService()
    
    private init() {}
    
    // MARK: - Smart Content Selection
    
    /// Get the best content to display for a user with intelligent language selection
    func getDisplayContent<T: LanguageAwareContent>(
        content: T,
        for userId: String,
        familyId: String,
        translationStatus: TranslationDisplayStatus = .completed
    ) async throws -> ContentDisplayResult<T> {
        print("🎯 Getting display content for user: \(userId)")
        
        // Get user's display preferences
        let preferences = try await FamilyLanguageService.shared.getDisplayPreferences(
            for: userId,
            familyId: familyId
        )
        
        // Make language selection decision
        let decision = FamilyLanguageService.shared.selectDisplayLanguage(
            content: content,
            userPreferences: preferences,
            translationStatus: translationStatus
        )
        
        // Extract the appropriate content based on the decision
        let displayText = extractContentText(
            from: content,
            language: decision.selectedLanguage
        )
        
        return ContentDisplayResult(
            content: content,
            displayText: displayText,
            selectedLanguage: decision.selectedLanguage,
            decision: decision,
            preferences: preferences,
            translationStatus: translationStatus
        )
    }
    
    /// Get display content for multiple items efficiently
    func getDisplayContentBatch<T: LanguageAwareContent>(
        contents: [T],
        for userId: String,
        familyId: String,
        translationStatuses: [String: TranslationDisplayStatus] = [:]
    ) async throws -> [ContentDisplayResult<T>] {
        print("🎯 Getting batch display content for \(contents.count) items")
        
        // Get user's display preferences once for all content
        let preferences = try await FamilyLanguageService.shared.getDisplayPreferences(
            for: userId,
            familyId: familyId
        )
        
        var results: [ContentDisplayResult<T>] = []
        
        for content in contents {
            // Get translation status for this specific content
            let contentId = getContentId(from: content)
            let translationStatus = translationStatuses[contentId] ?? .completed
            
            // Make language selection decision
            let decision = FamilyLanguageService.shared.selectDisplayLanguage(
                content: content,
                userPreferences: preferences,
                translationStatus: translationStatus
            )
            
            // Extract the appropriate content
            let displayText = extractContentText(
                from: content,
                language: decision.selectedLanguage
            )
            
            let result = ContentDisplayResult(
                content: content,
                displayText: displayText,
                selectedLanguage: decision.selectedLanguage,
                decision: decision,
                preferences: preferences,
                translationStatus: translationStatus
            )
            
            results.append(result)
        }
        
        print("✅ Processed \(results.count) content items for display")
        return results
    }
    
    // MARK: - Translation Status Integration
    
    /// Get translation status for guidance content
    func getGuidanceTranslationStatus(guidanceId: String) async throws -> TranslationDisplayStatus {
        do {
            let response = try await SupabaseManager.shared.client
                .from("guidance")
                .select("translation_status, secondary_content, secondary_language")
                .eq("id", value: guidanceId)
                .execute()
            
            let guidanceList = response.value as? [[String: Any]] ?? []
            
            guard let guidance = guidanceList.first,
                  let statusString = guidance["translation_status"] as? String else {
                return .notNeeded
            }
            
            return mapDatabaseStatusToDisplayStatus(statusString)
            
        } catch {
            print("❌ Error getting translation status: \(error)")
            return .completed // Default to completed to avoid blocking UI
        }
    }
    
    /// Get translation statuses for multiple guidance items
    func getGuidanceTranslationStatuses(guidanceIds: [String]) async throws -> [String: TranslationDisplayStatus] {
        guard !guidanceIds.isEmpty else { return [:] }
        
        do {
            let response = try await SupabaseManager.shared.client
                .from("guidance")
                .select("id, translation_status, secondary_content, secondary_language")
                .in("id", values: guidanceIds)
                .execute()
            
            let guidanceList = response.value as? [[String: Any]] ?? []
            
            var statuses: [String: TranslationDisplayStatus] = [:]
            
            for guidance in guidanceList {
                guard let id = guidance["id"] as? String,
                      let statusString = guidance["translation_status"] as? String else {
                    continue
                }
                
                statuses[id] = mapDatabaseStatusToDisplayStatus(statusString)
            }
            
            return statuses
            
        } catch {
            print("❌ Error getting batch translation statuses: \(error)")
            // Return completed status for all to avoid blocking UI
            return guidanceIds.reduce(into: [:]) { result, id in
                result[id] = .completed
            }
        }
    }
    
    // MARK: - Content-Specific Display Logic
    
    /// Get display text for Guidance content
    func getGuidanceDisplayText(
        guidance: Guidance,
        language: String
    ) -> String {
        return guidance.getContent(for: language)
    }
    
    /// Get display text for Situation content
    func getSituationDisplayText(
        situation: Situation,
        language: String,
        includeDescription: Bool = true
    ) -> String {
        let title = situation.getTitle(for: language)
        if includeDescription {
            let description = situation.getDescription(for: language)
            return "\(title)\n\(description)"
        } else {
            return title
        }
    }
    
    /// Get display text for FrameworkRecommendation content
    func getFrameworkDisplayText(
        framework: FrameworkRecommendation,
        language: String,
        includeNotification: Bool = true
    ) -> String {
        let name = framework.getFrameworkName(for: language)
        if includeNotification {
            let notification = framework.getNotificationText(for: language)
            return "\(name)\n\(notification)"
        } else {
            return name
        }
    }
    
    // MARK: - Language Switch Support
    
    /// Check if content can be switched to an alternative language
    func canSwitchLanguage<T: LanguageAwareContent>(
        content: T,
        preferences: DisplayPreferences
    ) -> Bool {
        return preferences.canSwitchLanguages && 
               (content.secondaryLanguage != nil || content.originalLanguage != preferences.preferredLanguage)
    }
    
    /// Get alternative language for content switching
    func getAlternativeLanguage<T: LanguageAwareContent>(
        content: T,
        currentLanguage: String
    ) -> String? {
        if currentLanguage == content.originalLanguage {
            return content.secondaryLanguage
        } else {
            return content.originalLanguage
        }
    }
    
    /// Switch content to alternative language
    func switchContentLanguage<T: LanguageAwareContent>(
        result: ContentDisplayResult<T>
    ) -> ContentDisplayResult<T>? {
        guard let alternativeLanguage = getAlternativeLanguage(
            content: result.content,
            currentLanguage: result.selectedLanguage
        ) else {
            return nil
        }
        
        let newDisplayText = extractContentText(
            from: result.content,
            language: alternativeLanguage
        )
        
        let newDecision = LanguageDisplayDecision(
            selectedLanguage: alternativeLanguage,
            reason: .userPreferenceUnavailable, // Placeholder - we'll need to handle this properly
            canSwitchLanguages: true,
            alternativeLanguage: result.selectedLanguage
        )
        
        return ContentDisplayResult(
            content: result.content,
            displayText: newDisplayText,
            selectedLanguage: alternativeLanguage,
            decision: newDecision,
            preferences: result.preferences,
            translationStatus: result.translationStatus
        )
    }
    
    // MARK: - Helper Methods
    
    private func extractContentText<T: LanguageAwareContent>(
        from content: T,
        language: String
    ) -> String {
        switch content {
        case let guidance as Guidance:
            return getGuidanceDisplayText(guidance: guidance, language: language)
        case let situation as Situation:
            return getSituationDisplayText(situation: situation, language: language)
        case let framework as FrameworkRecommendation:
            return getFrameworkDisplayText(framework: framework, language: language)
        default:
            // Fallback for unknown content types
            return "Content available in \(language)"
        }
    }
    
    private func getContentId<T: LanguageAwareContent>(from content: T) -> String {
        switch content {
        case let guidance as Guidance:
            return guidance.id
        case let situation as Situation:
            return situation.id
        case let framework as FrameworkRecommendation:
            return framework.id
        default:
            return UUID().uuidString
        }
    }
    
    private func mapDatabaseStatusToDisplayStatus(_ dbStatus: String) -> TranslationDisplayStatus {
        switch dbStatus.lowercased() {
        case "not_needed":
            return .notNeeded
        case "pending":
            return .pending
        case "in_progress":
            return .inProgress
        case "completed":
            return .completed
        case "failed":
            return .failed
        case "retrying":
            return .retrying
        default:
            return .completed
        }
    }
}

// MARK: - Supporting Models

/// Result of content display processing
struct ContentDisplayResult<T: LanguageAwareContent> {
    let content: T
    let displayText: String
    let selectedLanguage: String
    let decision: LanguageDisplayDecision
    let preferences: DisplayPreferences
    let translationStatus: TranslationDisplayStatus
    
    /// Whether this content can be switched to another language
    var canSwitchLanguage: Bool {
        return decision.canSwitchLanguages
    }
    
    /// The alternative language if switching is available
    var alternativeLanguage: String? {
        return decision.alternativeLanguage
    }
    
    /// Human-readable description of why this language was selected
    var selectionReason: String {
        return decision.reason.description
    }
}

/// Extended display reasons including user actions
enum ContentDisplayReason {
    case preferredLanguageAvailable
    case fallbackToOriginal
    case showingOriginalWhilePending
    case secondaryLanguageOnly
    case userPreferenceUnavailable
    case userSwitchedLanguage
    
    var description: String {
        switch self {
        case .preferredLanguageAvailable:
            return "Content available in user's preferred language"
        case .fallbackToOriginal:
            return "Preferred language unavailable, showing original"
        case .showingOriginalWhilePending:
            return "Showing original while translation is pending"
        case .secondaryLanguageOnly:
            return "Only secondary language version available"
        case .userPreferenceUnavailable:
            return "User preference could not be determined"
        case .userSwitchedLanguage:
            return "User manually switched language"
        }
    }
    
    /// Map from FamilyLanguageService DisplayReason
    static func from(_ displayReason: DisplayReason) -> ContentDisplayReason {
        switch displayReason {
        case .preferredLanguageAvailable:
            return .preferredLanguageAvailable
        case .fallbackToOriginal:
            return .fallbackToOriginal
        case .showingOriginalWhilePending:
            return .showingOriginalWhilePending
        case .secondaryLanguageOnly:
            return .secondaryLanguageOnly
        case .userPreferenceUnavailable:
            return .userPreferenceUnavailable
        }
    }
}