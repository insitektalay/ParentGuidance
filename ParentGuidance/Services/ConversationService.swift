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
    private init() {}
    
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
        category: String? = nil,
        isIncident: Bool = false
    ) async throws -> String {
        let situation = Situation(
            familyId: familyId,
            childId: childId,
            title: title,
            description: description,
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
        apiKey: String,
        category: String? = nil
    ) async throws -> String {
        print("🌐 Starting dual-language guidance generation")
        print("📝 Content preview: \(content.prefix(100))...")
        print("🏠 Family ID: \(familyId)")
        
        // Step 1: Save original guidance using existing method
        let guidanceId = try await saveGuidance(
            situationId: situationId,
            content: content,
            category: category
        )
        
        print("✅ Original guidance saved with ID: \(guidanceId)")
        
        // Step 2: Check if family needs dual-language content
        do {
            let needsTranslation = try await FamilyLanguageService.shared.shouldGenerateDualLanguage(for: familyId)
            
            guard needsTranslation else {
                print("ℹ️ Family uses single language, no translation needed")
                return guidanceId
            }
            
            print("🌍 Family uses multiple languages, generating translation...")
            
            // Step 3: Get target language for translation
            guard let targetLanguageCode = try await FamilyLanguageService.shared.getSecondaryLanguageCode(for: familyId) else {
                print("⚠️ Could not determine secondary language, skipping translation")
                return guidanceId
            }
            
            let targetLanguageName = FamilyLanguageService.shared.getLanguageName(for: targetLanguageCode)
            print("🎯 Translating to: \(targetLanguageName) (\(targetLanguageCode))")
            
            // Step 4: Translate content using TranslationService
            let translatedContent = try await TranslationService.shared.translateContent(
                text: content,
                targetLanguage: targetLanguageName,
                apiKey: apiKey
            )
            
            print("✅ Translation completed")
            print("📝 Translated preview: \(translatedContent.prefix(100))...")
            
            // Step 5: Validate translation quality
            let validation = TranslationService.shared.validateTranslation(
                original: content,
                translated: translatedContent
            )
            
            if !validation.isValid {
                print("⚠️ Translation validation warnings: \(validation.warnings.joined(separator: ", "))")
                // Continue anyway but log the warnings
            }
            
            // Step 6: Update guidance with translated content
            try await updateGuidanceWithTranslation(
                guidanceId: guidanceId,
                secondaryContent: translatedContent,
                secondaryLanguage: targetLanguageCode
            )
            
            print("✅ Dual-language guidance generation completed successfully")
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
