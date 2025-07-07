//
//  FrameworkStorageService.swift
//  ParentGuidance
//
//  Created by alex kerss on 07/07/2025.
//

import Foundation
import Supabase
import PostgREST

// MARK: - Database Models

struct StoredFrameworkRecommendation: Codable {
    let id: String
    let familyId: String
    let frameworkType: String
    let frameworkName: String
    let notificationText: String
    let detailedExplanation: String
    let situationIds: String
    let createdAt: String
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case frameworkType = "framework_type"
        case frameworkName = "framework_name"
        case notificationText = "notification_text"
        case detailedExplanation = "detailed_explanation"
        case situationIds = "situation_ids"
        case createdAt = "created_at"
        case isActive = "is_active"
    }
}

struct FrameworkInsertRecord: Codable {
    let familyId: String
    let frameworkType: String
    let frameworkName: String
    let notificationText: String
    let detailedExplanation: String
    let situationIds: String
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case familyId = "family_id"
        case frameworkType = "framework_type"
        case frameworkName = "framework_name"
        case notificationText = "notification_text"
        case detailedExplanation = "detailed_explanation"
        case situationIds = "situation_ids"
        case isActive = "is_active"
    }
}

// MARK: - Storage Errors

enum FrameworkStorageError: Error, LocalizedError {
    case invalidFramework
    case databaseError(String)
    case networkError
    case frameworkNotFound
    case activationError
    
    var errorDescription: String? {
        switch self {
        case .invalidFramework:
            return "The framework recommendation is invalid and cannot be saved"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .networkError:
            return "Network connection error. Please check your internet connection"
        case .frameworkNotFound:
            return "Framework recommendation not found"
        case .activationError:
            return "Failed to activate framework recommendation"
        }
    }
}

// MARK: - Framework Storage Service

class FrameworkStorageService {
    static let shared = FrameworkStorageService()
    
    private let supabase = SupabaseManager.shared.client
    private let tableName = "framework_recommendations"
    
    private init() {}
    
    // MARK: - Save Framework Recommendation
    
    /// Save a framework recommendation to the database
    /// - Parameters:
    ///   - recommendation: The framework recommendation to save
    ///   - familyId: The family ID this recommendation belongs to
    ///   - situationIds: Array of situation IDs used to generate this recommendation
    /// - Returns: The ID of the saved framework recommendation
    func saveFrameworkRecommendation(
        _ recommendation: FrameworkRecommendation,
        familyId: String,
        situationIds: [String]
    ) async throws -> String {
        print("💾 Saving framework recommendation to database...")
        print("   Framework: \(recommendation.frameworkName)")
        print("   Family ID: \(familyId)")
        print("   Situation IDs: \(situationIds)")
        
        // Validate input
        guard recommendation.isValid else {
            throw FrameworkStorageError.invalidFramework
        }
        
        do {
            // Convert to proper encodable format
            let insertRecord = FrameworkInsertRecord(
                familyId: familyId,
                frameworkType: recommendation.frameworkType?.rawValue ?? "unknown",
                frameworkName: recommendation.frameworkName,
                notificationText: recommendation.notificationText,
                detailedExplanation: recommendation.notificationText,
                situationIds: situationIds.joined(separator: ","),
                isActive: true
            )
            
            // Insert into database
            let response: [StoredFrameworkRecommendation] = try await supabase
                .from(tableName)
                .insert(insertRecord)
                .select()
                .execute()
                .value
            
            guard let savedFramework = response.first else {
                throw FrameworkStorageError.databaseError("Failed to retrieve saved framework")
            }
            
            print("✅ Framework recommendation saved with ID: \(savedFramework.id)")
            return savedFramework.id
            
        } catch {
            print("❌ Failed to save framework recommendation: \(error)")
            throw FrameworkStorageError.databaseError(error.localizedDescription)
        }
    }
    
    // MARK: - Retrieve Framework Recommendations
    
    /// Get the currently active framework for a family
    /// - Parameter familyId: The family ID to get the active framework for
    /// - Returns: The active framework recommendation, or nil if none exists
    func getActiveFramework(familyId: String) async throws -> FrameworkRecommendation? {
        print("🔍 Getting active framework for family: \(familyId)")
        
        do {
            let response: [StoredFrameworkRecommendation] = try await supabase
                .from(tableName)
                .select()
                .eq("family_id", value: familyId)
                .eq("is_active", value: true)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            guard let storedFramework = response.first else {
                print("📭 No active framework found for family")
                return nil
            }
            
            let recommendation = try convertToFrameworkRecommendation(storedFramework)
            print("✅ Found active framework: \(recommendation.frameworkName)")
            return recommendation
            
        } catch {
            print("❌ Failed to get active framework: \(error)")
            throw FrameworkStorageError.databaseError(error.localizedDescription)
        }
    }
    
    /// Get all framework recommendations for a family (active and historical)
    /// - Parameter familyId: The family ID to get frameworks for
    /// - Returns: Array of framework recommendations, ordered by creation date (newest first)
    func getFrameworkHistory(familyId: String) async throws -> [FrameworkRecommendation] {
        print("📚 Getting framework history for family: \(familyId)")
        
        do {
            let response: [StoredFrameworkRecommendation] = try await supabase
                .from(tableName)
                .select()
                .eq("family_id", value: familyId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            let recommendations = try response.map { try convertToFrameworkRecommendation($0) }
            print("✅ Found \(recommendations.count) framework recommendations")
            return recommendations
            
        } catch {
            print("❌ Failed to get framework history: \(error)")
            throw FrameworkStorageError.databaseError(error.localizedDescription)
        }
    }
    
    /// Get a specific framework recommendation by ID
    /// - Parameter frameworkId: The ID of the framework recommendation to retrieve
    /// - Returns: The framework recommendation
    func getFrameworkRecommendation(id: String) async throws -> FrameworkRecommendation {
        print("🔍 Getting framework recommendation: \(id)")
        
        do {
            let response: [StoredFrameworkRecommendation] = try await supabase
                .from(tableName)
                .select()
                .eq("id", value: id)
                .execute()
                .value
            
            guard let storedFramework = response.first else {
                throw FrameworkStorageError.frameworkNotFound
            }
            
            let recommendation = try convertToFrameworkRecommendation(storedFramework)
            print("✅ Found framework recommendation: \(recommendation.frameworkName)")
            return recommendation
            
        } catch {
            print("❌ Failed to get framework recommendation: \(error)")
            throw FrameworkStorageError.databaseError(error.localizedDescription)
        }
    }
    
    // MARK: - Framework Activation Management
    
    /// Activate a framework recommendation (deactivates all others for the family)
    /// - Parameter frameworkId: The ID of the framework to activate
    func activateFramework(id: String) async throws {
        print("🔄 Activating framework: \(id)")
        
        do {
            // Get the stored framework to access family_id
            let response: [StoredFrameworkRecommendation] = try await supabase
                .from(tableName)
                .select()
                .eq("id", value: id)
                .execute()
                .value
            
            guard let storedFramework = response.first else {
                throw FrameworkStorageError.frameworkNotFound
            }
            
            // Deactivate all frameworks for this family
            try await supabase
                .from(tableName)
                .update(["is_active": false])
                .eq("family_id", value: storedFramework.familyId)
                .execute()
            
            // Activate the selected framework
            try await supabase
                .from(tableName)
                .update(["is_active": true])
                .eq("id", value: id)
                .execute()
            
            print("✅ Framework activated successfully")
            
        } catch {
            print("❌ Failed to activate framework: \(error)")
            throw FrameworkStorageError.activationError
        }
    }
    
    /// Deactivate a framework recommendation
    /// - Parameter frameworkId: The ID of the framework to deactivate
    func deactivateFramework(id: String) async throws {
        print("🔄 Deactivating framework: \(id)")
        
        do {
            try await supabase
                .from(tableName)
                .update(["is_active": false])
                .eq("id", value: id)
                .execute()
            
            print("✅ Framework deactivated successfully")
            
        } catch {
            print("❌ Failed to deactivate framework: \(error)")
            throw FrameworkStorageError.activationError
        }
    }
    
    /// Deactivate all frameworks for a family
    /// - Parameter familyId: The family ID to deactivate frameworks for
    func deactivateAllFrameworks(familyId: String) async throws {
        print("🔄 Deactivating all frameworks for family: \(familyId)")
        
        do {
            try await supabase
                .from(tableName)
                .update(["is_active": false])
                .eq("family_id", value: familyId)
                .execute()
            
            print("✅ All frameworks deactivated successfully")
            
        } catch {
            print("❌ Failed to deactivate frameworks: \(error)")
            throw FrameworkStorageError.activationError
        }
    }
    
    // MARK: - Helper Methods
    
    /// Convert a stored framework record to a FrameworkRecommendation
    private func convertToFrameworkRecommendation(_ stored: StoredFrameworkRecommendation) throws -> FrameworkRecommendation {
        return FrameworkRecommendation(
            id: stored.id,
            frameworkName: stored.frameworkName,
            notificationText: stored.notificationText,
            createdAt: stored.createdAt
        )
    }
    
    /// Delete a framework recommendation (for testing/cleanup)
    /// - Parameter frameworkId: The ID of the framework to delete
    func deleteFrameworkRecommendation(id: String) async throws {
        print("🗑️ Deleting framework recommendation: \(id)")
        
        do {
            try await supabase
                .from(tableName)
                .delete()
                .eq("id", value: id)
                .execute()
            
            print("✅ Framework recommendation deleted successfully")
            
        } catch {
            print("❌ Failed to delete framework recommendation: \(error)")
            throw FrameworkStorageError.databaseError(error.localizedDescription)
        }
    }
}

// MARK: - PostgreSQL Conformance

extension FrameworkType: PostgrestFilterValue {
    public var postgrestFilterValue: String {
        return self.rawValue
    }
}

// MARK: - Database Schema Reference

/*
 Expected database table structure for framework_recommendations:
 
 CREATE TABLE framework_recommendations (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     family_id UUID NOT NULL REFERENCES families(id),
     framework_type VARCHAR(50) NOT NULL,
     framework_name VARCHAR(255) NOT NULL,
     notification_text TEXT NOT NULL,
     detailed_explanation TEXT NOT NULL,
     situation_ids JSONB NOT NULL,
     is_active BOOLEAN DEFAULT true,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
 CREATE INDEX idx_framework_recommendations_family_id ON framework_recommendations(family_id);
 CREATE INDEX idx_framework_recommendations_active ON framework_recommendations(family_id, is_active);
 
 Example situation_ids JSONB format:
 ["uuid1", "uuid2", "uuid3"]
 
 This table stores generated framework recommendations and allows:
 - One active framework per family (enforced by application logic)
 - Historical tracking of all generated frameworks
 - Efficient queries by family_id and active status
 - Linking recommendations back to the situations used to generate them
 */
