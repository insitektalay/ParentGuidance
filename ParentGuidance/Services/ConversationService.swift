//
//  ConversationService.swift
//  ParentGuidance
//
//  Created by alex kerss on 06/07/2025.
//

import Foundation
import SwiftUI
import Supabase

// MARK: - ConversationService
class ConversationService: ObservableObject {
    static let shared = ConversationService()
    
    /// Feature flag to use Edge Function instead of direct OpenAI API
    private let useEdgeFunction = UserDefaults.standard.bool(forKey: "conversation_use_edge_function")
    
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
        print("📊 Getting today's situations for family: \(familyId)")

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

            print("✅ Found \(response.count) situations for today")
            return response
        } catch {
            print("❌ Error getting today's situations: \(error)")
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
        
        print("💾 Saving situation to database...")
        print("   Title: \(title)")
        print("   Description: \(description.prefix(50))...")
        
        do {
            try await SupabaseManager.shared.client
                .from("situations")
                .insert(situation)
                .execute()
            
            print("✅ Situation saved successfully with ID: \(situation.id)")
            return situation.id
        } catch {
            print("❌ Error saving situation: \(error.localizedDescription)")
            throw error
        }
    }
    
    func saveGuidance(
        situationId: String,
        content: String,
        category: String? = nil
    ) async throws -> String {
        print("🔍 [DEBUG] Starting saveGuidance method")
        print("🔍 [DEBUG] Input parameters:")
        print("   - situationId: \(situationId)")
        print("   - content length: \(content.count) characters")
        print("   - content preview: \(content.prefix(100))...")
        print("   - category: \(category ?? "nil")")
        
        let guidanceId = UUID().uuidString
        let currentDate = ISO8601DateFormatter().string(from: Date())
        
        print("🔍 [DEBUG] Generated values:")
        print("   - guidanceId: \(guidanceId)")
        print("   - currentDate: \(currentDate)")
        
        let guidance = Guidance(
            id: guidanceId,
            situationId: situationId,
            content: content,
            category: category,
            createdAt: currentDate,
            updatedAt: currentDate
        )
        
        print("🔍 [DEBUG] Created Guidance object successfully")
        print("💾 Attempting to save guidance to Supabase...")
        
        do {
            print("🔍 [DEBUG] Calling Supabase client insert...")
            let response = try await SupabaseManager.shared.client
                .from("guidance")
                .insert(guidance)
                .execute()
            
            print("🔍 [DEBUG] Supabase response received")
            print("🔍 [DEBUG] Response data: \(response)")
            print("✅ Guidance saved successfully with ID: \(guidance.id)")
            return guidance.id
        } catch {
            print("❌ [ERROR] Failed to save guidance!")
            print("❌ [ERROR] Error type: \(type(of: error))")
            print("❌ [ERROR] Error description: \(error.localizedDescription)")
            print("❌ [ERROR] Full error: \(error)")
            if let encodingError = error as? EncodingError {
                print("❌ [ERROR] Encoding error details: \(encodingError)")
            }
            throw error
        }
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
        
        do {
            // First delete all related guidance
            try await SupabaseManager.shared.client
                .from("guidance")
                .delete()
                .eq("situation_id", value: situationId)
                .execute()
            
            print("✅ Deleted related guidance for situation")
            
            // Then delete the situation itself
            try await SupabaseManager.shared.client
                .from("situations")
                .delete()
                .eq("id", value: situationId)
                .execute()
            
            print("✅ Situation deleted successfully")
        } catch {
            print("❌ Error deleting situation: \(error)")
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
            
            print("✅ Analysis completed via Edge Function - Category: \(category), Incident: \(isIncident)")
            return (category: category, isIncident: isIncident)
            
        } catch {
            print("❌ Edge Function analysis failed: \(error)")
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
        print("🔄 Using direct API for situation analysis (legacy)")
        
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
        
        print("📡 Making analysis API request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response for analysis")
            throw NSError(domain: "AnalysisError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Analysis HTTP error: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Analysis error response: \(responseString)")
            }
            // Return defaults on API failure instead of throwing
            print("⚠️ Analysis failed, using defaults")
            return (category: nil, isIncident: false)
        }
        
        print("✅ Analysis HTTP 200 response received")
        
        do {
            // Parse using the same PromptResponse structure
            let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
            
            guard let firstOutput = promptResponse.output.first,
                  let firstContent = firstOutput.content.first else {
                print("❌ No content in analysis response")
                return (category: nil, isIncident: false)
            }
            
            let content = firstContent.text
            print("📝 Analysis content received: \(content)")
            
            // Parse the JSON response - wrap in braces to make valid JSON
            let wrappedJson = "{\(content)}"
            print("📝 Wrapped JSON: \(wrappedJson)")
            
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
                
                print("✅ Analysis completed - Category: \(category ?? "nil"), Incident: \(isIncident)")
                return (category: category, isIncident: isIncident)
            } else {
                print("❌ Failed to parse analysis JSON response")
                print("❌ Raw content was: \(content)")
                return (category: nil, isIncident: false)
            }
            
        } catch {
            print("❌ Error parsing analysis response: \(error)")
            return (category: nil, isIncident: false)
        }
    }
}
