//
//  FamilyLanguageService.swift
//  ParentGuidance
//
//  Created by alex kerss on 19/07/2025.
//

import Foundation
import Supabase

/// Translation generation strategy for families
enum TranslationGenerationStrategy: String, CaseIterable {
    case immediate = "immediate"        // Translate immediately after content generation
    case onDemand = "on_demand"         // Translate when first accessed by user
    case hybrid = "hybrid"             // Smart strategy based on usage patterns
    
    var description: String {
        switch self {
        case .immediate:
            return "Immediate Translation (Higher quality, more API usage)"
        case .onDemand:
            return "On-Demand Translation (Cost-effective, slight delay)"
        case .hybrid:
            return "Smart Translation (Optimized for your family's usage)"
        }
    }
}

/// Usage pattern data for intelligent translation decisions
struct FamilyUsagePattern {
    let familyId: String
    let avgContentAccessesPerDay: Double
    let primaryAccessLanguage: String
    let secondaryAccessLanguage: String?
    let contentReuseRate: Double // How often content is accessed multiple times
    let lastAnalyzed: Date
    
    /// Recommend optimal strategy based on usage patterns
    var recommendedStrategy: TranslationGenerationStrategy {
        // High usage families benefit from immediate translation
        if avgContentAccessesPerDay > 10 && contentReuseRate > 0.6 {
            return .immediate
        }
        // Low usage families should use on-demand
        else if avgContentAccessesPerDay < 3 {
            return .onDemand
        }
        // Medium usage benefits from hybrid approach
        else {
            return .hybrid
        }
    }
}

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
    
    // MARK: - Generation Strategy Management
    
    /// Get the current translation generation strategy for a family
    func getTranslationStrategy(for familyId: String) async throws -> TranslationGenerationStrategy {
        print("📊 Getting translation strategy for family: \(familyId)")
        
        do {
            let response = try await SupabaseManager.shared.client
                .from("families")
                .select("translation_strategy")
                .eq("id", value: familyId)
                .execute()
            
            let families = response.value as? [[String: Any]] ?? []
            
            if let family = families.first,
               let strategyString = family["translation_strategy"] as? String,
               let strategy = TranslationGenerationStrategy(rawValue: strategyString) {
                print("✅ Found strategy: \(strategy.rawValue) for family \(familyId)")
                return strategy
            }
            
            // Default to hybrid strategy for new families
            print("⚠️ No strategy found, defaulting to hybrid for family \(familyId)")
            return .hybrid
            
        } catch {
            print("❌ Error getting translation strategy: \(error)")
            // Return default strategy on error
            return .hybrid
        }
    }
    
    /// Set the translation generation strategy for a family
    func setTranslationStrategy(_ strategy: TranslationGenerationStrategy, for familyId: String) async throws {
        print("📊 Setting translation strategy to \(strategy.rawValue) for family: \(familyId)")
        
        do {
            try await SupabaseManager.shared.client
                .from("families")
                .update([
                    "translation_strategy": strategy.rawValue,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: familyId)
                .execute()
            
            print("✅ Successfully updated translation strategy for family \(familyId)")
            
        } catch {
            print("❌ Error setting translation strategy: \(error)")
            throw error
        }
    }
    
    /// Analyze family usage patterns and recommend optimal strategy
    func analyzeFamilyUsagePattern(for familyId: String) async throws -> FamilyUsagePattern {
        print("📊 Analyzing usage patterns for family: \(familyId)")
        
        do {
            // Get content access statistics from the last 30 days
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let dateFormatter = ISO8601DateFormatter()
            
            let response = try await SupabaseManager.shared.client
                .from("situations")
                .select("""
                    id,
                    created_at,
                    original_language,
                    profiles!inner(
                        preferred_language
                    )
                """)
                .eq("family_id", value: familyId)
                .gte("created_at", value: dateFormatter.string(from: thirtyDaysAgo))
                .execute()
            
            let situations = response.value as? [[String: Any]] ?? []
            
            // Calculate usage metrics
            let totalAccesses = Double(situations.count)
            let avgAccessesPerDay = totalAccesses / 30.0
            
            // Determine primary and secondary languages
            let languageFrequency = situations.compactMap { situation -> String? in
                guard let profile = situation["profiles"] as? [String: Any],
                      let language = profile["preferred_language"] as? String else {
                    return nil
                }
                return language
            }.reduce(into: [:]) { counts, language in
                counts[language, default: 0] += 1
            }
            
            let sortedLanguages = languageFrequency.sorted { $0.value > $1.value }
            let primaryLanguage = sortedLanguages.first?.key ?? "en"
            let secondaryLanguage = sortedLanguages.count > 1 ? sortedLanguages[1].key : nil
            
            // Estimate content reuse rate (simplified calculation)
            let contentReuseRate = min(1.0, totalAccesses > 0 ? (totalAccesses * 0.3) / totalAccesses : 0.0)
            
            let usagePattern = FamilyUsagePattern(
                familyId: familyId,
                avgContentAccessesPerDay: avgAccessesPerDay,
                primaryAccessLanguage: primaryLanguage,
                secondaryAccessLanguage: secondaryLanguage,
                contentReuseRate: contentReuseRate,
                lastAnalyzed: Date()
            )
            
            print("✅ Usage analysis complete:")
            print("   - Avg accesses/day: \(avgAccessesPerDay)")
            print("   - Primary language: \(primaryLanguage)")
            print("   - Secondary language: \(secondaryLanguage ?? "none")")
            print("   - Recommended strategy: \(usagePattern.recommendedStrategy.rawValue)")
            
            return usagePattern
            
        } catch {
            print("❌ Error analyzing usage patterns: \(error)")
            // Return default pattern on error
            return FamilyUsagePattern(
                familyId: familyId,
                avgContentAccessesPerDay: 1.0,
                primaryAccessLanguage: "en",
                secondaryAccessLanguage: nil,
                contentReuseRate: 0.3,
                lastAnalyzed: Date()
            )
        }
    }
    
    /// Get smart translation recommendation based on content and usage patterns
    func getSmartTranslationRecommendation(
        for familyId: String,
        contentType: String = "guidance",
        priority: TranslationPriority = .medium
    ) async throws -> SmartTranslationRecommendation {
        print("🧠 Getting smart translation recommendation for family: \(familyId)")
        
        let strategy = try await getTranslationStrategy(for: familyId)
        let usagePattern = try await analyzeFamilyUsagePattern(for: familyId)
        
        switch strategy {
        case .immediate:
            return SmartTranslationRecommendation(
                shouldTranslateNow: true,
                estimatedDelay: 0,
                reason: "Immediate strategy - translate all content right away",
                priority: priority
            )
            
        case .onDemand:
            return SmartTranslationRecommendation(
                shouldTranslateNow: false,
                estimatedDelay: 30, // 30 seconds typical translation time
                reason: "On-demand strategy - translate when first accessed",
                priority: .low
            )
            
        case .hybrid:
            // Hybrid logic based on usage patterns and content priority
            let shouldTranslateNow = usagePattern.avgContentAccessesPerDay > 5 || 
                                   priority == .high ||
                                   usagePattern.contentReuseRate > 0.5
            
            return SmartTranslationRecommendation(
                shouldTranslateNow: shouldTranslateNow,
                estimatedDelay: shouldTranslateNow ? 0 : 30,
                reason: shouldTranslateNow ? 
                    "High usage family - proactive translation" : 
                    "Low usage detected - on-demand translation",
                priority: shouldTranslateNow ? priority : .low
            )
        }
    }
    
    // MARK: - Content Display and Language Selection
    
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
                print("✅ Content available in user's preferred language: \(userLanguage)")
                return userLanguage
            } else {
                print("⚠️ Content not available in preferred language, using original")
                return content.originalLanguage
            }
        } catch {
            print("❌ Error getting user language preference: \(error)")
            return content.originalLanguage
        }
    }
    
    // MARK: - User-Specific Language Preferences (Phase 4)
    
    /// Get the optimal display language for content based on user preferences and availability
    func getOptimalDisplayLanguage(
        for userId: String,
        content: any LanguageAwareContent,
        fallbackToOriginal: Bool = true
    ) async throws -> String {
        print("🌍 Getting optimal display language for user: \(userId)")
        
        do {
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
            
            return DisplayPreferences(
                userId: userId,
                preferredLanguage: userProfile.preferredLanguage,
                fallbackLanguage: familyConfig.primaryLanguage,
                familyLanguages: familyConfig.uniqueLanguages,
                showOriginalWhenTranslationPending: true,
                isMultilingualFamily: familyConfig.needsDualLanguage,
                canSwitchLanguages: familyConfig.needsDualLanguage
            )
            
        } catch {
            print("❌ Error getting display preferences: \(error)")
            // Return default preferences with English
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
        print("🎯 Selecting display language for content")
        print("   - User prefers: \(userPreferences.preferredLanguage)")
        print("   - Translation status: \(translationStatus)")
        
        // Handle pending translations
        if translationStatus == .pending || translationStatus == .inProgress {
            return LanguageDisplayDecision(
                selectedLanguage: content.originalLanguage,
                reason: .showingOriginalWhilePending,
                canSwitchLanguages: false,
                alternativeLanguage: nil
            )
        }
        
        // Check if content is available in user's preferred language
        if content.hasContentInLanguage(userPreferences.preferredLanguage) {
            return LanguageDisplayDecision(
                selectedLanguage: userPreferences.preferredLanguage,
                reason: .preferredLanguageAvailable,
                canSwitchLanguages: userPreferences.canSwitchLanguages,
                alternativeLanguage: userPreferences.canSwitchLanguages ? content.originalLanguage : nil
            )
        }
        
        // Fallback to original language
        print("⚠️ Falling back to original language")
        return LanguageDisplayDecision(
            selectedLanguage: content.originalLanguage,
            reason: .fallbackToOriginal,
            canSwitchLanguages: userPreferences.canSwitchLanguages,
            alternativeLanguage: userPreferences.canSwitchLanguages ? content.secondaryLanguage : nil
        )
    }
    
    // MARK: - Content Language Management
    
    /// Get content needs for dual-language generation
    func getContentLanguageNeeds(for familyId: String) async throws -> ContentLanguageNeeds {
        let configuration = try await getFamilyLanguageConfiguration(familyId: familyId)
        
        guard configuration.needsDualLanguage else {
            return ContentLanguageNeeds(
                requiresTranslation: false,
                sourceLanguage: configuration.primaryLanguage,
                targetLanguage: nil
            )
        }
        
        let secondaryLanguage = try await getFamilySecondaryLanguage(familyId: familyId)
        
        return ContentLanguageNeeds(
            requiresTranslation: true,
            sourceLanguage: configuration.primaryLanguage,
            targetLanguage: secondaryLanguage
        )
    }
    
    // MARK: - Language Name Mapping for Translation API
    
    /// Convert language codes to human-readable names for OpenAI translation
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
        case "ja":
            return "Japanese"
        case "ko":
            return "Korean"
        case "zh":
            return "Chinese"
        case "ar":
            return "Arabic"
        case "hi":
            return "Hindi"
        case "th":
            return "Thai"
        case "vi":
            return "Vietnamese"
        case "pl":
            return "Polish"
        case "tr":
            return "Turkish"
        case "nl":
            return "Dutch"
        case "sv":
            return "Swedish"
        case "da":
            return "Danish"
        case "no":
            return "Norwegian"
        case "fi":
            return "Finnish"
        case "he":
            return "Hebrew"
        case "cs":
            return "Czech"
        case "hu":
            return "Hungarian"
        case "ro":
            return "Romanian"
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
        case "mt":
            return "Maltese"
        case "ga":
            return "Irish"
        case "cy":
            return "Welsh"
        case "is":
            return "Icelandic"
        case "mk":
            return "Macedonian"
        case "sq":
            return "Albanian"
        case "bs":
            return "Bosnian"
        case "sr":
            return "Serbian"
        case "me":
            return "Montenegrin"
        default:
            // For unrecognized codes, return capitalized version
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
        guard let languageCode = try await getFamilySecondaryLanguage(familyId: familyId) else {
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
            return "Family uses only one language"
        case .multilingualFamily:
            return "Family has multiple language preferences"
        case .unsupportedLanguage:
            return "Content language not supported by family members"
        case .noTranslationNeeded:
            return "All family members can read the original language"
        }
    }
}

/// Analysis of content language needs for a family
struct ContentLanguageAnalysis {
    let familyId: String
    let primaryLanguage: String
    let secondaryLanguage: String?
    let contentNeedingTranslation: [String] // Content IDs that need translation
}

/// Content language needs for dual-language generation
struct ContentLanguageNeeds {
    let requiresTranslation: Bool
    let sourceLanguage: String
    let targetLanguage: String?
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

// MARK: - Generation Strategy Models

/// Priority levels for translation requests
enum TranslationPriority {
    case low
    case medium
    case high
}

/// Smart translation recommendation based on usage patterns
struct SmartTranslationRecommendation {
    let shouldTranslateNow: Bool
    let estimatedDelay: TimeInterval // in seconds
    let reason: String
    let priority: TranslationPriority
    
    var isImmediate: Bool {
        return shouldTranslateNow && estimatedDelay == 0
    }
}