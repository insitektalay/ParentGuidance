//
//  FamilyLanguageService.swift
//  ParentGuidance
//
//  Created by alex kerss on 19/07/2025.
//

import Foundation
import Supabase

/// Service for managing family language configuration and dual-language content needs
class FamilyLanguageService {
    static let shared = FamilyLanguageService()
    
    private init() {}
    
    // MARK: - Family Language Configuration
    
    /// Get all parents in a family with their language preferences
    func getFamilyLanguageConfiguration(familyId: String) async throws -> FamilyLanguageConfiguration {
        print("🌍 Getting family language configuration for family: \(familyId)")
        
        do {
            let response: [UserProfile] = try await SupabaseManager.shared.client
                .from("profiles")
                .select("id, preferred_language")
                .eq("family_id", value: familyId)
                .execute()
                .value
            
            let languages = response.map { $0.preferredLanguage }
            let uniqueLanguages = Set(languages)
            
            print("✅ Found \(response.count) family members with languages: \(languages)")
            
            return FamilyLanguageConfiguration(
                familyId: familyId,
                memberLanguages: languages,
                uniqueLanguages: Array(uniqueLanguages),
                needsDualLanguage: uniqueLanguages.count > 1
            )
        } catch {
            print("❌ Error getting family language configuration: \(error)")
            // Return default configuration on error
            return FamilyLanguageConfiguration(
                familyId: familyId,
                memberLanguages: ["en"],
                uniqueLanguages: ["en"],
                needsDualLanguage: false
            )
        }
    }
    
    /// Check if a family needs dual-language content generation
    func familyNeedsDualLanguageContent(familyId: String) async throws -> Bool {
        let configuration = try await getFamilyLanguageConfiguration(familyId: familyId)
        return configuration.needsDualLanguage
    }
    
    /// Get the secondary language for a family (if applicable)
    func getFamilySecondaryLanguage(familyId: String) async throws -> String? {
        let configuration = try await getFamilyLanguageConfiguration(familyId: familyId)
        
        // If there are exactly 2 unique languages, return the non-English one
        // If neither is English, return the second one alphabetically
        if configuration.uniqueLanguages.count == 2 {
            let sorted = configuration.uniqueLanguages.sorted()
            if sorted.contains("en") {
                return sorted.first { $0 != "en" }
            } else {
                return sorted[1] // Return second one alphabetically
            }
        }
        
        return nil
    }
    
    // MARK: - Language Compatibility Analysis
    
    /// Determine if content needs translation for a specific family
    func shouldTranslateContent(
        originalLanguage: String,
        familyId: String
    ) async throws -> TranslationNeeds {
        let configuration = try await getFamilyLanguageConfiguration(familyId: familyId)
        
        // If family only has one language, no translation needed
        guard configuration.needsDualLanguage else {
            return TranslationNeeds(
                needsTranslation: false,
                targetLanguage: nil,
                reason: .singleLanguageFamily
            )
        }
        
        // Check if original language matches any family member's preference
        let hasOriginalLanguageSpeaker = configuration.memberLanguages.contains(originalLanguage)
        
        // Find the other language in the family
        let otherLanguages = configuration.uniqueLanguages.filter { $0 != originalLanguage }
        
        if hasOriginalLanguageSpeaker && !otherLanguages.isEmpty {
            // Original language is spoken by someone, translate to the other language
            return TranslationNeeds(
                needsTranslation: true,
                targetLanguage: otherLanguages.first,
                reason: .multilingualFamily
            )
        } else if !hasOriginalLanguageSpeaker {
            // Original language not spoken by anyone, translate to family's primary language
            let primaryLanguage = configuration.memberLanguages.first ?? "en"
            return TranslationNeeds(
                needsTranslation: true,
                targetLanguage: primaryLanguage,
                reason: .unsupportedLanguage
            )
        }
        
        return TranslationNeeds(
            needsTranslation: false,
            targetLanguage: nil,
            reason: .noTranslationNeeded
        )
    }
    
    /// Get the appropriate language for displaying content to a specific user
    func getDisplayLanguage(
        for userId: String,
        content: any LanguageAwareContent
    ) async throws -> String {
        print("🌍 Getting display language for user: \(userId)")
        
        do {
            let response: [UserProfile] = try await SupabaseManager.shared.client
                .from("profiles")
                .select("preferred_language")
                .eq("id", value: userId)
                .execute()
                .value
            
            guard let userProfile = response.first else {
                print("⚠️ User profile not found, defaulting to English")
                return "en"
            }
            
            let userLanguage = userProfile.preferredLanguage
            
            // Check if content has user's preferred language
            if content.hasContentInLanguage(userLanguage) {
                return userLanguage
            } else {
                // Fallback to original language
                return content.originalLanguage
            }
        } catch {
            print("❌ Error getting user language preference: \(error)")
            return content.originalLanguage
        }
    }
    
    // MARK: - User-Specific Language Preferences (Phase 4)
    
    /// Get the optimal display language for a specific user viewing specific content
    func getOptimalDisplayLanguage(
        for userId: String,
        content: any LanguageAwareContent,
        fallbackToOriginal: Bool = true
    ) async throws -> String {
        print("🌍 Getting optimal display language for user: \(userId)")
        
        do {
            // Get user's preferred language
            let response: [UserProfile] = try await SupabaseManager.shared.client
                .from("profiles")
                .select("preferred_language")
                .eq("id", value: userId)
                .execute()
                .value
            
            guard let userProfile = response.first else {
                print("⚠️ User profile not found, using original language")
                return content.originalLanguage
            }
            
            let userPreferredLanguage = userProfile.preferredLanguage
            print("👤 User prefers language: \(userPreferredLanguage)")
            
            // Check content availability in user's preferred language
            if content.hasContentInLanguage(userPreferredLanguage) {
                print("✅ Content available in user's preferred language")
                return userPreferredLanguage
            }
            
            // If content not available in preferred language, use fallback logic
            if fallbackToOriginal {
                print("⚠️ Content not available in preferred language, falling back to original")
                return content.originalLanguage
            } else {
                // Try secondary language if available
                if let secondaryLang = content.secondaryLanguage {
                    print("⚠️ Using secondary language as fallback: \(secondaryLang)")
                    return secondaryLang
                } else {
                    print("⚠️ No secondary language available, using original")
                    return content.originalLanguage
                }
            }
            
        } catch {
            print("❌ Error getting user language preference: \(error)")
            return content.originalLanguage
        }
    }
    
    /// Get display preferences for a family member with intelligent fallbacks
    func getDisplayPreferences(for userId: String, familyId: String) async throws -> DisplayPreferences {
        print("🌍 Getting display preferences for user: \(userId) in family: \(familyId)")
        
        do {
            // Get user profile
            let userResponse: [UserProfile] = try await SupabaseManager.shared.client
                .from("profiles")
                .select("preferred_language")
                .eq("id", value: userId)
                .execute()
                .value
            
            guard let userProfile = userResponse.first else {
                throw DisplayError.userNotFound
            }
            
            // Get family language configuration
            let familyConfig = try await getFamilyLanguageConfiguration(familyId: familyId)
            
            let userLanguage = userProfile.preferredLanguage
            let isUserLanguageSupported = familyConfig.uniqueLanguages.contains(userLanguage)
            
            return DisplayPreferences(
                userId: userId,
                preferredLanguage: userLanguage,
                fallbackLanguage: familyConfig.primaryLanguage,
                familyLanguages: familyConfig.uniqueLanguages,
                showOriginalWhenTranslationPending: true,
                isMultilingualFamily: familyConfig.needsDualLanguage,
                canSwitchLanguages: familyConfig.needsDualLanguage && isUserLanguageSupported
            )
            
        } catch {
            print("❌ Error getting display preferences: \(error)")
            
            // Return default preferences on error
            return DisplayPreferences(
                userId: userId,
                preferredLanguage: "en",
                fallbackLanguage: "en",
                familyLanguages: ["en"],
                showOriginalWhenTranslationPending: true,
                isMultilingualFamily: false,
                canSwitchLanguages: false
            )
        }
    }
    
    /// Determine the best language to display content based on user preferences and content availability
    func selectDisplayLanguage(
        content: any LanguageAwareContent,
        userPreferences: DisplayPreferences,
        translationStatus: TranslationDisplayStatus = .completed
    ) -> LanguageDisplayDecision {
        print("🔍 Selecting display language for content")
        print("   - User prefers: \(userPreferences.preferredLanguage)")
        print("   - Translation status: \(translationStatus)")
        print("   - Content has original: \(content.originalLanguage)")
        print("   - Content has secondary: \(content.secondaryLanguage ?? "none")")
        
        // If translation is pending and user prefers to show original
        if translationStatus == .pending && userPreferences.showOriginalWhenTranslationPending {
            print("✅ Showing original while translation pending")
            return LanguageDisplayDecision(
                selectedLanguage: content.originalLanguage,
                reason: .showingOriginalWhilePending,
                canSwitchLanguages: false,
                alternativeLanguage: nil
            )
        }
        
        // Check if content is available in user's preferred language
        if content.hasContentInLanguage(userPreferences.preferredLanguage) {
            let alternativeLanguage = content.originalLanguage != userPreferences.preferredLanguage 
                ? content.originalLanguage 
                : content.secondaryLanguage
            
            print("✅ Content available in preferred language")
            return LanguageDisplayDecision(
                selectedLanguage: userPreferences.preferredLanguage,
                reason: .preferredLanguageAvailable,
                canSwitchLanguages: userPreferences.canSwitchLanguages && alternativeLanguage != nil,
                alternativeLanguage: alternativeLanguage
            )
        }
        
        // Fallback to original language
        print("⚠️ Falling back to original language")
        return LanguageDisplayDecision(
            selectedLanguage: content.originalLanguage,
            reason: .fallbackToOriginal,
            canSwitchLanguages: userPreferences.canSwitchLanguages && content.secondaryLanguage != nil,
            alternativeLanguage: content.secondaryLanguage
        )
    }
    
    // MARK: - Content Language Management
    
    /// Analyze existing content and suggest language updates needed
    func analyzeContentLanguageNeeds(familyId: String) async throws -> ContentLanguageAnalysis {
        let configuration = try await getFamilyLanguageConfiguration(familyId: familyId)
        
        guard configuration.needsDualLanguage else {
            return ContentLanguageAnalysis(
                familyId: familyId,
                needsDualLanguageSupport: false,
                recommendedSecondaryLanguage: nil,
                contentNeedingTranslation: []
            )
        }
        
        let secondaryLanguage = try await getFamilySecondaryLanguage(familyId: familyId)
        
        // For now, return basic analysis - this could be expanded to check existing content
        return ContentLanguageAnalysis(
            familyId: familyId,
            needsDualLanguageSupport: true,
            recommendedSecondaryLanguage: secondaryLanguage,
            contentNeedingTranslation: [] // TODO: Could analyze existing situations/guidance
        )
    }
    
    // MARK: - Language Name Mapping for Translation API
    
    /// Convert language code to full language name for translation API
    func getLanguageName(for languageCode: String) -> String {
        switch languageCode.lowercased() {
        case "en":
            return "English"
        case "es":
            return "Spanish"
        case "fr":
            return "French"
        case "de":
            return "German"
        case "it":
            return "Italian"
        case "pt":
            return "Portuguese"
        case "ru":
            return "Russian"
        case "zh":
            return "Chinese"
        case "ja":
            return "Japanese"
        case "ko":
            return "Korean"
        case "ar":
            return "Arabic"
        case "hi":
            return "Hindi"
        case "nl":
            return "Dutch"
        case "sv":
            return "Swedish"
        case "no":
            return "Norwegian"
        case "da":
            return "Danish"
        case "fi":
            return "Finnish"
        case "pl":
            return "Polish"
        case "cs":
            return "Czech"
        case "hu":
            return "Hungarian"
        case "tr":
            return "Turkish"
        case "he":
            return "Hebrew"
        case "th":
            return "Thai"
        case "vi":
            return "Vietnamese"
        case "uk":
            return "Ukrainian"
        case "bg":
            return "Bulgarian"
        case "hr":
            return "Croatian"
        case "sk":
            return "Slovak"
        case "sl":
            return "Slovenian"
        case "et":
            return "Estonian"
        case "lv":
            return "Latvian"
        case "lt":
            return "Lithuanian"
        case "ro":
            return "Romanian"
        case "el":
            return "Greek"
        case "is":
            return "Icelandic"
        case "mt":
            return "Maltese"
        case "ga":
            return "Irish"
        case "cy":
            return "Welsh"
        case "eu":
            return "Basque"
        case "ca":
            return "Catalan"
        case "gl":
            return "Galician"
        case "ur":
            return "Urdu"
        case "fa":
            return "Persian"
        case "sw":
            return "Swahili"
        case "ms":
            return "Malay"
        case "id":
            return "Indonesian"
        case "tl":
            return "Filipino"
        default:
            // Fallback: capitalize the language code
            return languageCode.capitalized
        }
    }
    
    /// Enhanced method for dual-language generation (Phase 2 integration)
    func shouldGenerateDualLanguage(for familyId: String) async throws -> Bool {
        return try await familyNeedsDualLanguageContent(familyId: familyId)
    }
    
    /// Get secondary language code for a family (Phase 2 integration)
    func getSecondaryLanguageCode(for familyId: String) async throws -> String? {
        return try await getFamilySecondaryLanguage(familyId: familyId)
    }
    
    /// Get secondary language name for translation API (Phase 2 integration)
    func getSecondaryLanguageName(for familyId: String) async throws -> String? {
        guard let languageCode = try await getSecondaryLanguageCode(for: familyId) else {
            return nil
        }
        return getLanguageName(for: languageCode)
    }
}

// MARK: - Supporting Models

/// Configuration of languages within a family
struct FamilyLanguageConfiguration {
    let familyId: String
    let memberLanguages: [String]
    let uniqueLanguages: [String]
    let needsDualLanguage: Bool
    
    /// Primary language (most common or first)
    var primaryLanguage: String {
        return memberLanguages.first ?? "en"
    }
    
    /// Secondary language (if applicable)
    var secondaryLanguage: String? {
        guard uniqueLanguages.count >= 2 else { return nil }
        return uniqueLanguages.first { $0 != primaryLanguage }
    }
}

/// Represents whether content needs translation
struct TranslationNeeds {
    let needsTranslation: Bool
    let targetLanguage: String?
    let reason: TranslationReason
}

/// Reasons why translation might be needed
enum TranslationReason {
    case singleLanguageFamily
    case multilingualFamily
    case unsupportedLanguage
    case noTranslationNeeded
    
    var description: String {
        switch self {
        case .singleLanguageFamily:
            return "Family only speaks one language"
        case .multilingualFamily:
            return "Family has multiple language preferences"
        case .unsupportedLanguage:
            return "Content language not spoken by family members"
        case .noTranslationNeeded:
            return "All family members can read the original language"
        }
    }
}

/// Analysis of content language needs for a family
struct ContentLanguageAnalysis {
    let familyId: String
    let needsDualLanguageSupport: Bool
    let recommendedSecondaryLanguage: String?
    let contentNeedingTranslation: [String] // Content IDs that need translation
}

/// Protocol for content that supports multiple languages
protocol LanguageAwareContent {
    var originalLanguage: String { get }
    var secondaryLanguage: String? { get }
    func hasContentInLanguage(_ language: String) -> Bool
}

// MARK: - Phase 4 Supporting Models

/// User display preferences for multilingual content
struct DisplayPreferences {
    let userId: String
    let preferredLanguage: String
    let fallbackLanguage: String
    let familyLanguages: [String]
    let showOriginalWhenTranslationPending: Bool
    let isMultilingualFamily: Bool
    let canSwitchLanguages: Bool
}

/// Decision about which language to display for specific content
struct LanguageDisplayDecision {
    let selectedLanguage: String
    let reason: DisplayReason
    let canSwitchLanguages: Bool
    let alternativeLanguage: String?
}

/// Status of translation for display purposes
enum TranslationDisplayStatus {
    case notNeeded
    case pending
    case inProgress
    case completed
    case failed
    case retrying
}

/// Reasons for language display decisions
enum DisplayReason {
    case preferredLanguageAvailable
    case fallbackToOriginal
    case showingOriginalWhilePending
    case secondaryLanguageOnly
    case userPreferenceUnavailable
    
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
        }
    }
}

/// Errors related to display logic
enum DisplayError: LocalizedError {
    case userNotFound
    case familyNotFound
    case contentNotFound
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User profile not found"
        case .familyNotFound:
            return "Family configuration not found"
        case .contentNotFound:
            return "Content not found"
        }
    }
}

// MARK: - Protocol Conformance

extension Situation: LanguageAwareContent {}
extension Guidance: LanguageAwareContent {}
extension FrameworkRecommendation: LanguageAwareContent {}