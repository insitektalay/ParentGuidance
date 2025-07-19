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

// MARK: - Protocol Conformance

extension Situation: LanguageAwareContent {}
extension Guidance: LanguageAwareContent {}
extension FrameworkRecommendation: LanguageAwareContent {}