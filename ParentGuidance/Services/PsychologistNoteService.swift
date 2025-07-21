//
//  PsychologistNoteService.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import Foundation
import Supabase

class PsychologistNoteService {
    static let shared = PsychologistNoteService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Generate and store a psychologist's note for a child
    func generatePsychologistNote(
        familyId: String,
        childId: String? = nil,
        noteType: PsychologistNoteType,
        apiKey: String
    ) async throws -> PsychologistNote {
        print("🧠 Starting psychologist note generation")
        print("   → Family ID: \(familyId)")
        print("   → Child ID: \(childId ?? "nil")")
        print("   → Note Type: \(noteType.rawValue)")
        
        // Aggregate source data based on note type
        let (sourceData, sourceDataSummary) = try await aggregateSourceData(
            familyId: familyId,
            childId: childId,
            noteType: noteType
        )
        
        guard !sourceData.isEmpty else {
            print("❌ No source data available for note generation")
            throw PsychologistNoteError.noDataAvailable
        }
        
        print("📊 Source data aggregated: \(sourceData.count) characters")
        print("📝 Summary: \(sourceDataSummary)")
        
        // Generate AI content using EdgeFunction
        let generatedContent = try await generateNoteContentViaEdgeFunction(
            noteType: noteType,
            sourceData: sourceData,
            apiKey: apiKey
        )
        
        // Create note model
        let note = PsychologistNote(
            familyId: familyId,
            childId: childId,
            noteType: noteType,
            content: generatedContent,
            sourceDataSummary: sourceDataSummary
        )
        
        // Store in database
        try await storePsychologistNote(note)
        
        print("✅ Psychologist note generated and stored successfully")
        return note
    }
    
    /// Fetch all psychologist notes for a family
    func fetchPsychologistNotes(familyId: String) async throws -> [PsychologistNote] {
        print("📚 Fetching psychologist notes for family: \(familyId)")
        
        do {
            let response = try await SupabaseManager.shared.client
                .from("psychologist_notes")
                .select("*")
                .eq("family_id", value: familyId)
                .order("created_at", ascending: false)
                .execute()
            
            let notes = try JSONDecoder().decode([PsychologistNote].self, from: response.data)
            print("✅ Fetched \(notes.count) psychologist notes")
            return notes
            
        } catch {
            print("❌ Failed to fetch psychologist notes: \(error)")
            throw PsychologistNoteError.databaseError(error.localizedDescription)
        }
    }
    
    /// Fetch notes for a specific child
    func fetchPsychologistNotes(familyId: String, childId: String) async throws -> [PsychologistNote] {
        print("📚 Fetching psychologist notes for child: \(childId)")
        
        do {
            let response = try await SupabaseManager.shared.client
                .from("psychologist_notes")
                .select("*")
                .eq("family_id", value: familyId)
                .eq("child_id", value: childId)
                .order("created_at", ascending: false)
                .execute()
            
            let notes = try JSONDecoder().decode([PsychologistNote].self, from: response.data)
            print("✅ Fetched \(notes.count) psychologist notes for child")
            return notes
            
        } catch {
            print("❌ Failed to fetch psychologist notes for child: \(error)")
            throw PsychologistNoteError.databaseError(error.localizedDescription)
        }
    }
    
    /// Delete a psychologist note
    func deletePsychologistNote(noteId: String) async throws {
        print("🗑️ Deleting psychologist note: \(noteId)")
        
        do {
            try await SupabaseManager.shared.client
                .from("psychologist_notes")
                .delete()
                .eq("id", value: noteId)
                .execute()
            
            print("✅ Psychologist note deleted successfully")
            
        } catch {
            print("❌ Failed to delete psychologist note: \(error)")
            throw PsychologistNoteError.databaseError(error.localizedDescription)
        }
    }
    
    // MARK: - Private Methods
    
    /// Generate note content using EdgeFunction
    private func generateNoteContentViaEdgeFunction(
        noteType: PsychologistNoteType,
        sourceData: String,
        apiKey: String
    ) async throws -> String {
        print("🚀 Generating note content via EdgeFunction")
        print("   → Operation: \(noteType.promptOperation)")
        
        do {
            let response = try await EdgeFunctionService.shared.generatePsychologistNote(
                noteType: noteType,
                sourceData: sourceData,
                apiKey: apiKey
            )
            
            print("✅ Note content generated via EdgeFunction")
            return response
            
        } catch {
            print("❌ EdgeFunction note generation failed: \(error)")
            throw PsychologistNoteError.generationFailed(error.localizedDescription)
        }
    }
    
    /// Aggregate source data based on note type
    private func aggregateSourceData(
        familyId: String,
        childId: String?,
        noteType: PsychologistNoteType
    ) async throws -> (sourceData: String, summary: String) {
        print("📊 Aggregating source data for \(noteType.rawValue)")
        
        switch noteType {
        case .context:
            return try await aggregateContextualInsights(familyId: familyId, childId: childId)
        case .traits:
            return try await aggregateInsightBulletPoints(familyId: familyId, childId: childId)
        }
    }
    
    /// Aggregate data from contextual_insights table
    private func aggregateContextualInsights(
        familyId: String,
        childId: String?
    ) async throws -> (sourceData: String, summary: String) {
        print("📋 Aggregating contextual insights")
        
        do {
            let response = if let childId = childId {
                try await SupabaseManager.shared.client
                    .from("contextual_insights")
                    .select("content, category, subcategory, created_at")
                    .eq("family_id", value: familyId)
                    .eq("child_id", value: childId)
                    .order("created_at", ascending: true)
                    .execute()
            } else {
                try await SupabaseManager.shared.client
                    .from("contextual_insights")
                    .select("content, category, subcategory, created_at")
                    .eq("family_id", value: familyId)
                    .order("created_at", ascending: true)
                    .execute()
            }
            
            struct InsightRow: Codable {
                let content: String
                let category: String
                let subcategory: String?
                let createdAt: String
                
                enum CodingKeys: String, CodingKey {
                    case content
                    case category
                    case subcategory
                    case createdAt = "created_at"
                }
            }
            
            let insights = try JSONDecoder().decode([InsightRow].self, from: response.data)
            
            let sourceData = insights.map { insight in
                var line = "\(insight.category): \(insight.content)"
                if let subcategory = insight.subcategory {
                    line = "\(insight.category) - \(subcategory): \(insight.content)"
                }
                return line
            }.joined(separator: "\n\n")
            
            let summary = "Contextual insights from \(insights.count) observations across \(Set(insights.map(\.category)).count) categories"
            
            print("📊 Aggregated \(insights.count) contextual insights")
            return (sourceData, summary)
            
        } catch {
            print("❌ Failed to aggregate contextual insights: \(error)")
            throw PsychologistNoteError.databaseError(error.localizedDescription)
        }
    }
    
    /// Aggregate data from insight_bullet_points table
    private func aggregateInsightBulletPoints(
        familyId: String,
        childId: String?
    ) async throws -> (sourceData: String, summary: String) {
        print("🎯 Aggregating insight bullet points")
        
        do {
            let response = if let childId = childId {
                try await SupabaseManager.shared.client
                    .from("insight_bullet_points")
                    .select("content, category, created_at")
                    .eq("family_id", value: familyId)
                    .eq("child_id", value: childId)
                    .order("created_at", ascending: true)
                    .execute()
            } else {
                try await SupabaseManager.shared.client
                    .from("insight_bullet_points")
                    .select("content, category, created_at")
                    .eq("family_id", value: familyId)
                    .order("created_at", ascending: true)
                    .execute()
            }
            
            struct BulletPointRow: Codable {
                let content: String
                let category: String
                let createdAt: String
                
                enum CodingKeys: String, CodingKey {
                    case content
                    case category
                    case createdAt = "created_at"
                }
            }
            
            let bulletPoints = try JSONDecoder().decode([BulletPointRow].self, from: response.data)
            
            let sourceData = bulletPoints.map { point in
                "\(point.category): \(point.content)"
            }.joined(separator: "\n")
            
            let summary = "Behavioral insights from \(bulletPoints.count) observations across \(Set(bulletPoints.map(\.category)).count) categories"
            
            print("🎯 Aggregated \(bulletPoints.count) insight bullet points")
            return (sourceData, summary)
            
        } catch {
            print("❌ Failed to aggregate insight bullet points: \(error)")
            throw PsychologistNoteError.databaseError(error.localizedDescription)
        }
    }
    
    /// Store psychologist note in database
    private func storePsychologistNote(_ note: PsychologistNote) async throws {
        print("💾 Storing psychologist note in database")
        
        do {
            try await SupabaseManager.shared.client
                .from("psychologist_notes")
                .insert(note)
                .execute()
            
            print("✅ Psychologist note stored successfully")
            
        } catch {
            print("❌ Failed to store psychologist note: \(error)")
            throw PsychologistNoteError.databaseError(error.localizedDescription)
        }
    }
}