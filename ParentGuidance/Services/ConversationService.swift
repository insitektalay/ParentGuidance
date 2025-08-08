//
//  ConversationService.swift
//  ParentGuidance
//
//  Created by alex kerss on 06/07/2025.
//

import Foundation
import SwiftUI
import Supabase

// MARK: - ConversationError
enum ConversationError: LocalizedError {
    case deletionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .deletionFailed(let message):
            return message
        }
    }
}

// MARK: - ConversationService
class ConversationService: ObservableObject {
    static let shared = ConversationService()
    
    /// Feature flag to use Edge Function instead of direct OpenAI API
    /// Default to true to support multi-provider API keys (will be overridden by ResolvedPolicy when provided)
    private let useEdgeFunction = UserDefaults.standard.object(forKey: "conversation_use_edge_function") as? Bool ?? true
    
    private init() {}
    
    // MARK: - Configuration Methods
    
    /// Enable or disable Edge Function usage for situation analysis
    static func setUseEdgeFunction(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "conversation_use_edge_function")
        print("🔧 ConversationService Edge Function usage set to: \(enabled)")
    }
    
    /// Check if Edge Function is currently enabled
    static func isUsingEdgeFunction() -> Bool {
        return UserDefaults.standard.bool(forKey: "conversation_use_edge_function")
    }
    
    func getTodaysSituations(familyId: String) async throws -> [Situation] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        do {
            let response: [Situation] = try await SupabaseManager.shared.client
                .from("situations")
                .select("*")
                .eq("family_id", value: familyId)
                .gte("created_at", value: today)
                .lt("created_at", value: "\(today)T23:59:59")
                .order("created_at", ascending: true)
                .execute()
                .value

            return response
        } catch {
            return []
        }
    }
    
    func saveSituation(
        familyId: String?,
        childId: String?,
        title: String,
        description: String,
        situationType: String = "one_time",
        category: String? = nil,
        isIncident: Bool = false
    ) async throws -> String {
        let situation = Situation(
            familyId: familyId,
            childId: childId,
            title: title,
            description: description,
            situationType: situationType,
            category: category,
            isIncident: isIncident
        )
        
        do {
            try await SupabaseManager.shared.client
                .from("situations")
                .insert(situation)
                .execute()
            
            return situation.id
        } catch {
            print("❌ Error saving situation: \(error.localizedDescription)")
            throw error
        }
    }
    
    func saveGuidance(
        situationId: String,
        content: String,
        category: String? = nil,
        overallRecommendation: String? = nil,
        regenRunId: UUID? = nil,
        experimentRunId: UUID? = nil
    ) async throws -> String {
        let guidanceId = UUID().uuidString
        let currentDate = ISO8601DateFormatter().string(from: Date())
        
        let guidance = Guidance(
            id: guidanceId,
            situationId: situationId,
            content: content,
            category: category,
            overallRecommendation: overallRecommendation,
            createdAt: currentDate,
            updatedAt: currentDate
        )
        
        do {
            // Create a temporary struct that includes all fields
            struct GuidanceInsert: Encodable {
                let id: String
                let situationId: String
                let content: String
                let category: String?
                let originalLanguage: String
                let secondaryContent: String?
                let secondaryLanguage: String?
                let overallRecommendation: String?
                let createdAt: String
                let updatedAt: String
                let regenRunId: String?
                let experimentRunId: String?
                
                enum CodingKeys: String, CodingKey {
                    case id
                    case situationId = "situation_id"
                    case content
                    case category
                    case originalLanguage = "original_language"
                    case secondaryContent = "secondary_content"
                    case secondaryLanguage = "secondary_language"
                    case overallRecommendation = "overall_recommendation"
                    case createdAt = "created_at"
                    case updatedAt = "updated_at"
                    case regenRunId = "regen_run_id"
                    case experimentRunId = "experiment_run_id"
                }
            }
            
            let insertData = GuidanceInsert(
                id: guidance.id,
                situationId: guidance.situationId,
                content: guidance.content,
                category: guidance.category,
                originalLanguage: guidance.originalLanguage,
                secondaryContent: guidance.secondaryContent,
                secondaryLanguage: guidance.secondaryLanguage,
                overallRecommendation: guidance.overallRecommendation,
                createdAt: guidance.createdAt,
                updatedAt: guidance.updatedAt,
                regenRunId: regenRunId?.uuidString,
                experimentRunId: experimentRunId?.uuidString
            )
            
            let response = try await SupabaseManager.shared.client
                .from("guidance")
                .insert(insertData)
                .execute()
            
            return guidance.id
        } catch {
            print("❌ Failed to save guidance: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Guidance Generation
    
    /// Generate guidance for a situation
    func generateGuidance(
        situationId: UUID,
        situationText: String,
        childName: String,
        regenRunId: UUID? = nil,
        experimentRunId: UUID? = nil,
        resolvedPolicy: ResolvedPolicy? = nil
    ) async throws -> Guidance {
        // Get API key
        guard let apiKey = UserDefaults.standard.string(forKey: "openAIApiKey") else {
            throw ConversationError.deletionFailed("No API key found")
        }
        
        // Generate guidance using GuidanceGenerationService
        let (guidanceResponse, rawContent) = try await GuidanceGenerationService.shared.generateGuidance(
            situation: situationText,
            childContext: nil,
            keyInsights: nil,
            copingStrategies: nil,
            apiKey: apiKey,
            activeFramework: nil,
            situationType: .imJustWondering,
            useStreaming: false,
            policy: resolvedPolicy
        )
        
        // Extract overall recommendation
        let overallRecommendation = guidanceResponse.title
        
        // Save the guidance with regen/experiment IDs
        let guidanceId = try await saveGuidance(
            situationId: situationId.uuidString,
            content: rawContent,
            category: nil,
            overallRecommendation: overallRecommendation,
            regenRunId: regenRunId,
            experimentRunId: experimentRunId
        )
        
        // Return the created guidance
        return Guidance(
            id: guidanceId,
            situationId: situationId.uuidString,
            content: rawContent,
            category: nil,
            overallRecommendation: overallRecommendation
        )
    }
    
    // MARK: - Dual-Language Content Generation (Phase 2)
    
    /// Generate guidance with automatic translation for dual-language families
    func generateGuidanceWithTranslation(
        situationId: String,
        content: String,
        familyId: String,
        userId: String,
        apiKey: String,
        category: String? = nil
    ) async throws -> String {
        print("🌐 Starting smart dual-language guidance generation")
        print("📝 Content preview: \(content.prefix(100))...")
        print("🏠 Family ID: \(familyId)")
        print("👤 User ID: \(userId)")
        
        // Step 1: Save original guidance using existing method
        let guidanceId = try await saveGuidance(
            situationId: situationId,
            content: content,
            category: category
        )
        
        print("✅ Original guidance saved with ID: \(guidanceId)")
        
        // Step 2: Track content access for usage pattern analysis
        TranslationQueueManager.shared.trackContentAccess(
            contentId: guidanceId,
            familyId: familyId,
            userId: userId,
            language: "en" // Original language is English
        )
        
        // Step 3: Check if family needs dual-language content
        do {
            let needsTranslation = try await FamilyLanguageService.shared.shouldGenerateDualLanguage(for: familyId)
            
            guard needsTranslation else {
                print("ℹ️ Family uses single language, no translation needed")
                return guidanceId
            }
            
            print("🌍 Family uses multiple languages, generating translation...")
            
            // Step 4: Get target language for translation
            guard let targetLanguageCode = try await FamilyLanguageService.shared.getSecondaryLanguageCode(for: familyId) else {
                print("⚠️ Could not determine secondary language, skipping translation")
                return guidanceId
            }
            
            let targetLanguageName = FamilyLanguageService.shared.getLanguageName(for: targetLanguageCode)
            print("🎯 Translation needed for: \(targetLanguageName) (\(targetLanguageCode))")
            
            // Step 5: Get smart translation recommendation based on usage patterns
            let recommendation = try await FamilyLanguageService.shared.getSmartTranslationRecommendation(
                for: familyId,
                contentType: "guidance",
                priority: .high // New content starts with high priority
            )
            
            print("🧠 Smart recommendation: \(recommendation.shouldTranslateNow ? "immediate" : "on-demand")")
            print("   Reason: \(recommendation.reason)")
            print("   Estimated delay: \(recommendation.estimatedDelay)s")
            
            // Step 6: Update guidance with secondary language info and translation status
            if recommendation.shouldTranslateNow {
                // Immediate translation - mark as pending for high priority processing
                try await updateGuidanceForTranslation(
                    guidanceId: guidanceId,
                    secondaryLanguage: targetLanguageCode
                )
                
                // Step 7: Queue translation with smart priority
                let translationTask = TranslationQueueManager.TranslationTask(
                    id: UUID().uuidString,
                    guidanceId: guidanceId,
                    content: content,
                    targetLanguage: targetLanguageCode,
                    targetLanguageName: targetLanguageName,
                    familyId: familyId,
                    apiKey: apiKey,
                    priority: recommendation.priority == .high ? .high : .medium
                )
                
                TranslationQueueManager.shared.enqueue(task: translationTask)
                print("📥 Translation queued for immediate processing (high usage family)")
                
            } else {
                // On-demand translation - just set up the secondary language, don't queue yet
                try await updateGuidanceForOnDemandTranslation(
                    guidanceId: guidanceId,
                    secondaryLanguage: targetLanguageCode
                )
                print("⏰ Translation prepared for on-demand processing (low usage family)")
            }
            
            print("✅ Smart guidance generation completed")
            return guidanceId
            
        } catch {
            print("❌ Error during translation process: \(error)")
            print("⚠️ Continuing with original language only")
            // Return the original guidance ID even if translation fails
            return guidanceId
        }
    }
    
    /// Update existing guidance with translated content
    private func updateGuidanceWithTranslation(
        guidanceId: String,
        secondaryContent: String,
        secondaryLanguage: String
    ) async throws {
        print("📝 Updating guidance \(guidanceId) with translation")
        
        let updateData: [String: String] = [
            "secondary_content": secondaryContent,
            "secondary_language": secondaryLanguage,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            try await SupabaseManager.shared.client
                .from("guidance")
                .update(updateData)
                .eq("id", value: guidanceId)
                .execute()
            
            print("✅ Guidance updated with translation")
            
        } catch {
            print("❌ Failed to update guidance with translation: \(error)")
            throw error
        }
    }
    
    /// Update guidance to prepare for translation (Phase 3)
    private func updateGuidanceForTranslation(
        guidanceId: String,
        secondaryLanguage: String
    ) async throws {
        print("📝 Preparing guidance \(guidanceId) for translation")
        
        let updateData: [String: String] = [
            "secondary_language": secondaryLanguage,
            "translation_status": "pending",
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            try await SupabaseManager.shared.client
                .from("guidance")
                .update(updateData)
                .eq("id", value: guidanceId)
                .execute()
            
            print("✅ Guidance marked for translation")
            
        } catch {
            print("❌ Failed to prepare guidance for translation: \(error)")
            throw error
        }
    }
    
    /// Update guidance for on-demand translation (Phase 5.2)
    private func updateGuidanceForOnDemandTranslation(
        guidanceId: String,
        secondaryLanguage: String
    ) async throws {
        print("📝 Preparing guidance \(guidanceId) for on-demand translation")
        
        let updateData: [String: String] = [
            "secondary_language": secondaryLanguage,
            "translation_status": "not_needed",
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            try await SupabaseManager.shared.client
                .from("guidance")
                .update(updateData)
                .eq("id", value: guidanceId)
                .execute()
            
            print("✅ Guidance prepared for on-demand translation")
            
        } catch {
            print("❌ Failed to prepare guidance for on-demand translation: \(error)")
            throw error
        }
    }
    
    func createFamilyForUser(userId: String) async throws -> String {
        let familyId = UUID().uuidString
        let currentDate = ISO8601DateFormatter().string(from: Date())
        
        print("🏠 Creating family with ID: \(familyId)")
        
        let familyData: [String: String] = [
            "id": familyId,
            "created_at": currentDate,
            "updated_at": currentDate
        ]
        
        do {
            try await SupabaseManager.shared.client
                .from("families")
                .insert(familyData)
                .execute()
            
            print("✅ Family created successfully")
            
            try await SupabaseManager.shared.client
                .from("profiles")
                .update(["family_id": familyId])
                .eq("id", value: userId)
                .execute()
            
            print("✅ User profile updated with family_id")
            return familyId
            
        } catch {
            print("❌ Error creating family: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getAllSituations(familyId: String) async throws -> [Situation] {
        print("📚 Getting all situations for family: \(familyId)")
        
        do {
            let response: [Situation] = try await SupabaseManager.shared.client
                .from("situations")
                .select("*")
                .eq("family_id", value: familyId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("✅ Found \(response.count) total situations for family")
            return response
        } catch {
            print("❌ Error getting all situations: \(error)")
            throw error
        }
    }
    
    func getGuidanceForSituation(situationId: String) async throws -> [Guidance] {
        print("📋 Getting guidance for situation: \(situationId)")
        
        do {
            let response: [Guidance] = try await SupabaseManager.shared.client
                .from("guidance")
                .select("*")
                .eq("situation_id", value: situationId)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            print("✅ Found \(response.count) guidance entries for situation")
            return response
        } catch {
            print("❌ Error getting guidance for situation: \(error)")
            throw error
        }
    }
    
    // MARK: - Smart Translation Access Tracking (Phase 5.2)
    
    /// Enhanced guidance retrieval with smart translation triggering
    func getGuidanceForSituationWithSmartTranslation(
        situationId: String,
        userId: String,
        familyId: String,
        preferredLanguage: String,
        apiKey: String? = nil
    ) async throws -> [Guidance] {
        print("🧠 Getting guidance with smart translation for situation: \(situationId)")
        print("👤 User: \(userId), Family: \(familyId), Language: \(preferredLanguage)")
        
        // Get the guidance first
        let guidanceEntries = try await getGuidanceForSituation(situationId: situationId)
        
        // Track content access for each guidance entry
        for guidance in guidanceEntries {
            TranslationQueueManager.shared.trackContentAccess(
                contentId: guidance.id,
                familyId: familyId,
                userId: userId,
                language: preferredLanguage
            )
            
            // Check if on-demand translation should be triggered
            if preferredLanguage != "en" && 
               guidance.secondaryLanguage == preferredLanguage &&
               guidance.secondaryContent == nil {
                
                print("🔄 On-demand translation needed for guidance \(guidance.id)")
                
                // Check if we should proactively translate based on usage patterns
                let shouldTranslate = await TranslationQueueManager.shared.shouldProactivelyTranslate(
                    contentId: guidance.id,
                    familyId: familyId
                )
                
                if shouldTranslate, let apiKey = apiKey {
                    print("⚡ Triggering on-demand translation for high-value content")
                    await triggerOnDemandTranslation(
                        guidanceId: guidance.id,
                        content: guidance.content,
                        targetLanguage: guidance.secondaryLanguage ?? preferredLanguage,
                        familyId: familyId,
                        apiKey: apiKey
                    )
                }
            }
        }
        
        return guidanceEntries
    }
    
    /// Trigger on-demand translation for specific content
    private func triggerOnDemandTranslation(
        guidanceId: String,
        content: String,
        targetLanguage: String,
        familyId: String,
        apiKey: String
    ) async {
        print("⚡ Triggering on-demand translation for guidance: \(guidanceId)")
        
        let targetLanguageName = FamilyLanguageService.shared.getLanguageName(for: targetLanguage)
        
        // Update status to pending
        do {
            try await updateGuidanceForTranslation(
                guidanceId: guidanceId,
                secondaryLanguage: targetLanguage
            )
            
            // Create high-priority translation task
            let translationTask = TranslationQueueManager.TranslationTask(
                id: UUID().uuidString,
                guidanceId: guidanceId,
                content: content,
                targetLanguage: targetLanguage,
                targetLanguageName: targetLanguageName,
                familyId: familyId,
                apiKey: apiKey,
                priority: .high // On-demand requests get high priority
            )
            
            TranslationQueueManager.shared.enqueue(task: translationTask)
            print("📥 On-demand translation queued with high priority")
            
        } catch {
            print("❌ Failed to trigger on-demand translation: \(error)")
        }
    }
    
    /// Implement proactive translation for high-usage content
    func implementProactiveTranslation(familyId: String, apiKey: String) async {
        print("🚀 Implementing proactive translation for family: \(familyId)")
        
        // Get high-priority content for translation
        let highPriorityContent = TranslationQueueManager.shared.getHighPriorityContentForTranslation(
            familyId: familyId,
            limit: 10
        )
        
        print("📊 Found \(highPriorityContent.count) high-priority content items")
        
        for contentRecord in highPriorityContent {
            // Get the guidance to check if translation is needed
            do {
                let guidance: [Guidance] = try await SupabaseManager.shared.client
                    .from("guidance")
                    .select("*")
                    .eq("id", value: contentRecord.contentId)
                    .execute()
                    .value
                
                guard let guidance = guidance.first,
                      let secondaryLanguage = guidance.secondaryLanguage,
                      guidance.secondaryContent == nil else {
                    continue
                }
                
                print("🔄 Proactively translating high-usage content: \(guidance.id)")
                
                await triggerOnDemandTranslation(
                    guidanceId: guidance.id,
                    content: guidance.content,
                    targetLanguage: secondaryLanguage,
                    familyId: familyId,
                    apiKey: apiKey
                )
                
                // Add delay to avoid overwhelming the queue
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
            } catch {
                print("❌ Error during proactive translation: \(error)")
            }
        }
        
        print("✅ Proactive translation implementation completed")
    }
    
    // MARK: - New Methods for Step 4.6
    
    func deleteSituation(situationId: String) async throws {
        print("🗑️ Deleting situation: \(situationId)")
        
        var insightBulletPointsDeleted = false
        var contextualInsightsDeleted = false
        var guidanceDeleted = false
        var situationDeleted = false
        
        do {
            // First delete all related insight_bullet_points
            do {
                try await SupabaseManager.shared.client
                    .from("insight_bullet_points")
                    .delete()
                    .eq("situation_id", value: situationId)
                    .execute()
                
                insightBulletPointsDeleted = true
                print("✅ Deleted related insight bullet points for situation")
            } catch {
                print("❌ Error deleting insight bullet points: \(error)")
                // Continue even if this fails
            }
            
            // Delete any contextual insights that reference this situation
            do {
                try await SupabaseManager.shared.client
                    .from("contextual_insights")
                    .delete()
                    .eq("source_situation_id", value: situationId)
                    .execute()
                
                contextualInsightsDeleted = true
                print("✅ Deleted related contextual insights for situation")
            } catch {
                print("❌ Error deleting contextual insights: \(error)")
                // Continue even if this fails
            }
            
            // Delete all related guidance
            do {
                try await SupabaseManager.shared.client
                    .from("guidance")
                    .delete()
                    .eq("situation_id", value: situationId)
                    .execute()
                
                guidanceDeleted = true
                print("✅ Deleted related guidance for situation")
            } catch {
                print("❌ Error deleting guidance: \(error)")
                // Continue to try deleting the situation even if guidance fails
            }
            
            // Finally delete the situation itself
            do {
                try await SupabaseManager.shared.client
                    .from("situations")
                    .delete()
                    .eq("id", value: situationId)
                    .execute()
                
                situationDeleted = true
                print("✅ Situation deleted successfully")
            } catch {
                print("❌ Error deleting situation: \(error)")
                
                // Check if it's a foreign key constraint error
                if let postgrestError = error as? PostgrestError,
                   postgrestError.code == "23503" {
                    print("❌ Foreign key constraint violation - there are still related records")
                    throw ConversationError.deletionFailed("Cannot delete situation - there are still related records. Please contact support.")
                } else {
                    print("❌ Situation deletion failed - likely due to missing DELETE RLS policy")
                    throw ConversationError.deletionFailed("Failed to delete situation. Please check database permissions.")
                }
            }
            
        } catch {
            print("❌ Overall deletion error: \(error)")
            throw error
        }
    }
    
    func toggleSituationFavorite(situationId: String) async throws -> Bool {
        print("⭐ Toggling favorite status for situation: \(situationId)")
        
        do {
            // First get current favorite status
            let response: [Situation] = try await SupabaseManager.shared.client
                .from("situations")
                .select("*")
                .eq("id", value: situationId)
                .execute()
                .value
            
            guard let situation = response.first else {
                throw NSError(domain: "SituationNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Situation not found"])
            }
            
            let newFavoriteStatus = !situation.isFavorited
            
            // Update the favorite status
            try await SupabaseManager.shared.client
                .from("situations")
                .update(["is_favorited": newFavoriteStatus])
                .eq("id", value: situationId)
                .execute()
            
            print("✅ Favorite status updated to: \(newFavoriteStatus)")
            return newFavoriteStatus
        } catch {
            print("❌ Error toggling favorite status: \(error)")
            throw error
        }
    }
    
    func getFavoritedSituations(familyId: String) async throws -> Set<String> {
        print("⭐ Getting favorited situations for family: \(familyId)")
        
        do {
            let response: [Situation] = try await SupabaseManager.shared.client
                .from("situations")
                .select("id")
                .eq("family_id", value: familyId)
                .eq("is_favorited", value: true)
                .execute()
                .value
            
            let favoritedIds = Set(response.map { $0.id })
            print("✅ Found \(favoritedIds.count) favorited situations")
            return favoritedIds
        } catch {
            print("❌ Error getting favorited situations: \(error)")
            throw error
        }
    }
    
    func updateSituationDate(situationId: String, newDate: Date) async throws {
        print("📅 Updating situation date for: \(situationId)")
        
        // Validate that the new date is not in the future
        let now = Date()
        if newDate > now {
            throw NSError(domain: "InvalidDate", code: 400, userInfo: [NSLocalizedDescriptionKey: "Cannot set a future date"])
        }
        
        let isoFormatter = ISO8601DateFormatter()
        let newDateString = isoFormatter.string(from: newDate)
        
        do {
            try await SupabaseManager.shared.client
                .from("situations")
                .update([
                    "created_at": newDateString,
                    "updated_at": isoFormatter.string(from: now)
                ])
                .eq("id", value: situationId)
                .execute()
            
            print("✅ Situation date updated to: \(newDateString)")
        } catch {
            print("❌ Error updating situation date: \(error)")
            throw error
        }
    }
    
    // MARK: - Situation Analysis
    
    func analyzeSituation(situationText: String, apiKey: String, activeFramework: FrameworkRecommendation? = nil) async throws -> (category: String?, isIncident: Bool) {
        print("🔍 Analyzing situation: \(situationText.prefix(50))...")
        if let framework = activeFramework {
            print("📋 Framework context: \(framework.frameworkName)")
        }
        
        // Choose implementation based on feature flag
        if useEdgeFunction {
            return try await analyzeSituationViaEdgeFunction(
                situationText: situationText,
                apiKey: apiKey,
                activeFramework: activeFramework
            )
        } else {
            return try await analyzeSituationViaDirectAPI(
                situationText: situationText,
                apiKey: apiKey,
                activeFramework: activeFramework
            )
        }
    }
    
    /// Analyze situation using the new Edge Function approach
    private func analyzeSituationViaEdgeFunction(
        situationText: String,
        apiKey: String,
        activeFramework: FrameworkRecommendation? = nil
    ) async throws -> (category: String?, isIncident: Bool) {
        print("🔄 Using Edge Function for situation analysis")
        
        do {
            let (category, isIncident) = try await EdgeFunctionService.shared.analyzeSituation(
                situationText: situationText,
                apiKey: apiKey
            )
            
            return (category: category, isIncident: isIncident)
            
        } catch {
            // Fallback to defaults on error
            return (category: nil, isIncident: false)
        }
    }
    
    /// Analyze situation using the legacy direct API approach
    private func analyzeSituationViaDirectAPI(
        situationText: String,
        apiKey: String,
        activeFramework: FrameworkRecommendation? = nil
    ) async throws -> (category: String?, isIncident: Bool) {
        // Using direct API for situation analysis (legacy)
        
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "prompt": [
                "id": "pmpt_686b988bf0ac8196a69e972f08842b9a05893c8e8a5153c7",
                "version": "1",
                "variables": [
                    "situation_inputted": situationText
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AnalysisError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode != 200 {
            // Return defaults on API failure instead of throwing
            return (category: nil, isIncident: false)
        }
        
        do {
            // Parse using the same PromptResponse structure
            let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
            
            guard let firstOutput = promptResponse.output.first,
                  let firstContent = firstOutput.content.first else {
                return (category: nil, isIncident: false)
            }
            
            let content = firstContent.text
            
            // Parse the JSON response - wrap in braces to make valid JSON
            let wrappedJson = "{\(content)}"
            
            if let jsonData = wrappedJson.data(using: .utf8),
               let analysisResult = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                
                let category = analysisResult["category"] as? String
                let incident = analysisResult["incident"]
                
                // Handle both boolean and string incident values
                let isIncident: Bool
                if let boolValue = incident as? Bool {
                    isIncident = boolValue
                } else if let stringValue = incident as? String {
                    isIncident = stringValue.lowercased() == "true"
                } else {
                    isIncident = false
                }
                
                return (category: category, isIncident: isIncident)
            } else {
                return (category: nil, isIncident: false)
            }
            
        } catch {
            return (category: nil, isIncident: false)
        }
    }
}
