import Foundation
import Supabase

class ConversationService: ObservableObject {
    static let shared = ConversationService()
    private init() {}
    
    // MARK: - Save Situation
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
        print("   Family ID: \(familyId ?? "nil")")
        print("   Child ID: \(childId ?? "nil")")
        
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
    
    // MARK: - Save Guidance
    func saveGuidance(
        situationId: String,
        content: String,
        category: String? = nil
    ) async throws -> String {
        let guidance = Guidance(
            situationId: situationId,
            content: content,
            situationCategory: category,
            foundationToolEnhanced: true // Since we're using the OpenAI prompt with frameworks
        )
        
        print("💾 Saving guidance to database...")
        print("   Situation ID: \(situationId)")
        print("   Content length: \(content.count) characters")
        print("   Category: \(category ?? "nil")")
        
        do {
            try await SupabaseManager.shared.client
                .from("guidance")
                .insert(guidance)
                .execute()
            
            print("✅ Guidance saved successfully with ID: \(guidance.id)")
            return guidance.id
        } catch {
            print("❌ Error saving guidance: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Get Conversation History
    func getConversationHistory(
        familyId: String?,
        childId: String? = nil,
        limit: Int = 50
    ) async throws -> [ConversationPair] {
        print("📚 Loading conversation history...")
        print("   Family ID: \(familyId ?? "nil")")
        print("   Child ID: \(childId ?? "nil")")
        print("   Limit: \(limit)")
        
        do {
            // First get situations
            var situationsQuery = SupabaseManager.shared.client
                .from("situations")
                .select("*")
                .order("created_at", ascending: false)
                .limit(limit)
            
            if let familyId = familyId {
                situationsQuery = situationsQuery.eq("family_id", value: familyId)
            }
            
            if let childId = childId {
                situationsQuery = situationsQuery.eq("child_id", value: childId)
            }
            
            let situations: [Situation] = try await situationsQuery.execute().value
            print("📖 Found \(situations.count) situations")
            
            // Get guidance for each situation
            var conversationPairs: [ConversationPair] = []
            
            for situation in situations {
                let guidanceResponse: [Guidance] = try await SupabaseManager.shared.client
                    .from("guidance")
                    .select("*")
                    .eq("situation_id", value: situation.id)
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()
                    .value
                
                if let guidance = guidanceResponse.first {
                    conversationPairs.append(ConversationPair(situation: situation, guidance: guidance))
                }
            }
            
            print("✅ Loaded \(conversationPairs.count) conversation pairs")
            return conversationPairs
            
        } catch {
            print("❌ Error loading conversation history: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Get Single Conversation
    func getConversation(situationId: String) async throws -> ConversationPair? {
        print("🔍 Loading conversation for situation: \(situationId)")
        
        do {
            // Get the situation
            let situationResponse: [Situation] = try await SupabaseManager.shared.client
                .from("situations")
                .select("*")
                .eq("id", value: situationId)
                .execute()
                .value
            
            guard let situation = situationResponse.first else {
                print("❌ Situation not found")
                return nil
            }
            
            // Get the guidance
            let guidanceResponse: [Guidance] = try await SupabaseManager.shared.client
                .from("guidance")
                .select("*")
                .eq("situation_id", value: situationId)
                .execute()
                .value
            
            guard let guidance = guidanceResponse.first else {
                print("❌ Guidance not found for situation")
                return nil
            }
            
            print("✅ Conversation loaded successfully")
            return ConversationPair(situation: situation, guidance: guidance)
            
        } catch {
            print("❌ Error loading conversation: \(error.localizedDescription)")
            throw error
        }
    }
}