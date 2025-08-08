import Foundation
import Supabase

@MainActor
class GoldResponseService: ObservableObject {
    static let shared = GoldResponseService()
    
    private let supabaseManager = SupabaseManager.shared
    
    private init() {}
    
    // MARK: - Gold Response Management
    
    func getGoldResponse(for situationId: UUID) async throws -> GoldResponse? {
        let response = try await supabaseManager.client
            .from("gold_responses")
            .select()
            .eq("situation_id", value: situationId.uuidString)
            .order("version", ascending: false)
            .limit(1)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let goldResponses = try decoder.decode([GoldResponse].self, from: response.data)
        return goldResponses.first
    }
    
    func saveGoldResponse(
        situationId: UUID,
        familyId: UUID,
        fullResponse: String,
        responseSections: ResponseSections? = nil
    ) async throws -> GoldResponse {
        // Get the next version number
        let existingVersions = try await supabaseManager.client
            .from("gold_responses")
            .select("version")
            .eq("situation_id", value: situationId.uuidString)
            .order("version", ascending: false)
            .limit(1)
            .execute()
        
        let nextVersion: Int
        if existingVersions.data.isEmpty {
            nextVersion = 1
        } else {
            struct VersionResponse: Decodable {
                let version: Int
            }
            let versions = try JSONDecoder().decode([VersionResponse].self, from: existingVersions.data)
            nextVersion = (versions.first?.version ?? 0) + 1
        }
        
        let goldResponse = GoldResponse(
            id: UUID(),
            situationId: situationId,
            familyId: familyId,
            version: nextVersion,
            fullResponse: fullResponse,
            responseSections: responseSections,
            authorId: supabaseManager.getCurrentUserId(),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await supabaseManager.client
            .from("gold_responses")
            .insert(goldResponse)
            .execute()
        
        return goldResponse
    }
    
    func updateGoldResponse(
        id: UUID,
        fullResponse: String,
        responseSections: ResponseSections? = nil
    ) async throws {
        struct GoldResponseUpdate: Encodable {
            let fullResponse: String
            let responseSections: ResponseSections?
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case fullResponse = "full_response"
                case responseSections = "response_sections"
                case updatedAt = "updated_at"
            }
        }
        
        let updateData = GoldResponseUpdate(
            fullResponse: fullResponse,
            responseSections: responseSections,
            updatedAt: Date().ISO8601Format()
        )
        
        try await supabaseManager.client
            .from("gold_responses")
            .update(updateData)
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    func deleteGoldResponse(id: UUID) async throws {
        try await supabaseManager.client
            .from("gold_responses")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    func getGoldResponseVersions(for situationId: UUID) async throws -> [GoldResponse] {
        let response = try await supabaseManager.client
            .from("gold_responses")
            .select()
            .eq("situation_id", value: situationId.uuidString)
            .order("version", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([GoldResponse].self, from: response.data)
    }
    
    // MARK: - Redline Response Management
    
    func getRedlineResponse(for situationId: UUID) async throws -> RedlineResponse? {
        let response = try await supabaseManager.client
            .from("redline_responses")
            .select()
            .eq("situation_id", value: situationId.uuidString)
            .order("version", ascending: false)
            .limit(1)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let redlineResponses = try decoder.decode([RedlineResponse].self, from: response.data)
        return redlineResponses.first
    }
    
    func saveRedlineResponse(
        situationId: UUID,
        familyId: UUID,
        fullResponse: String,
        responseSections: ResponseSections? = nil
    ) async throws -> RedlineResponse {
        // Get the next version number
        let existingVersions = try await supabaseManager.client
            .from("redline_responses")
            .select("version")
            .eq("situation_id", value: situationId.uuidString)
            .order("version", ascending: false)
            .limit(1)
            .execute()
        
        let nextVersion: Int
        if existingVersions.data.isEmpty {
            nextVersion = 1
        } else {
            struct VersionResponse: Decodable {
                let version: Int
            }
            let versions = try JSONDecoder().decode([VersionResponse].self, from: existingVersions.data)
            nextVersion = (versions.first?.version ?? 0) + 1
        }
        
        let redlineResponse = RedlineResponse(
            id: UUID(),
            situationId: situationId,
            familyId: familyId,
            version: nextVersion,
            fullResponse: fullResponse,
            responseSections: responseSections,
            authorId: supabaseManager.getCurrentUserId(),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await supabaseManager.client
            .from("redline_responses")
            .insert(redlineResponse)
            .execute()
        
        return redlineResponse
    }
    
    func updateRedlineResponse(
        id: UUID,
        fullResponse: String,
        responseSections: ResponseSections? = nil
    ) async throws {
        struct RedlineResponseUpdate: Encodable {
            let fullResponse: String
            let responseSections: ResponseSections?
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case fullResponse = "full_response"
                case responseSections = "response_sections"
                case updatedAt = "updated_at"
            }
        }
        
        let updateData = RedlineResponseUpdate(
            fullResponse: fullResponse,
            responseSections: responseSections,
            updatedAt: Date().ISO8601Format()
        )
        
        try await supabaseManager.client
            .from("redline_responses")
            .update(updateData)
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    func deleteRedlineResponse(id: UUID) async throws {
        try await supabaseManager.client
            .from("redline_responses")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    func getRedlineResponseVersions(for situationId: UUID) async throws -> [RedlineResponse] {
        let response = try await supabaseManager.client
            .from("redline_responses")
            .select()
            .eq("situation_id", value: situationId.uuidString)
            .order("version", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([RedlineResponse].self, from: response.data)
    }
    
    // MARK: - Bulk Operations
    
    func exportGoldResponses(familyId: UUID) async throws -> Data {
        let response = try await supabaseManager.client
            .from("gold_responses")
            .select("*, situations!inner(text)")
            .eq("family_id", value: familyId.uuidString)
            .order("created_at", ascending: true)
            .execute()
        
        struct GoldResponseExport: Codable {
            let situationId: String
            let situationText: String
            let goldResponse: String
            let version: Int
            let createdAt: String
            
            enum CodingKeys: String, CodingKey {
                case situationId = "situation_id"
                case situationText = "situation_text"
                case goldResponse = "full_response"
                case version
                case createdAt = "created_at"
            }
        }
        
        // Transform the data for export
        // This would need to be implemented based on the actual response structure
        let exportData: [GoldResponseExport] = []
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try encoder.encode(exportData)
    }
    
    func importGoldResponses(familyId: UUID, data: Data) async throws {
        struct GoldResponseImport: Codable {
            let situationId: String
            let goldResponse: String
            let version: Int?
            
            enum CodingKeys: String, CodingKey {
                case situationId = "situation_id"
                case goldResponse = "gold_response"
                case version
            }
        }
        
        let decoder = JSONDecoder()
        let imports = try decoder.decode([GoldResponseImport].self, from: data)
        
        for importItem in imports {
            guard let situationId = UUID(uuidString: importItem.situationId) else {
                continue
            }
            
            try await saveGoldResponse(
                situationId: situationId,
                familyId: familyId,
                fullResponse: importItem.goldResponse
            )
        }
    }
}

// MARK: - Error Types

enum GoldResponseError: LocalizedError {
    case notFound
    case invalidVersion
    case importFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Gold response not found"
        case .invalidVersion:
            return "Invalid version number"
        case .importFailed(let message):
            return "Import failed: \(message)"
        }
    }
}