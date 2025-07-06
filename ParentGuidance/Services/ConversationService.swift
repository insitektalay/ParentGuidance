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
        description: String
    ) async throws -> String {
        let situation = Situation(
            familyId: familyId,
            childId: childId,
            title: title,
            description: description
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
}
