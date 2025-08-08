import Foundation
import Supabase

@MainActor
class RedlineResponseService: ObservableObject {
    static let shared = RedlineResponseService()
    
    private let supabaseManager = SupabaseManager.shared
    
    private init() {}
    
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
    
    // MARK: - Keyword Extraction
    
    func extractKeywords(from text: String) -> [String] {
        // Extract important phrases that should be avoided
        // This is a simple implementation - could be enhanced with NLP
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 3 }
        
        // Remove common stop words
        let stopWords = Set(["this", "that", "with", "from", "your", "have", "will", "what", "when", "where", "which", "their", "they", "them", "then", "than", "these", "those"])
        
        return words.filter { !stopWords.contains($0.lowercased()) }
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Bulk Operations
    
    func exportRedlineResponses(familyId: UUID) async throws -> Data {
        let _ = try await supabaseManager.client
            .from("redline_responses")
            .select("*, situations!inner(text)")
            .eq("family_id", value: familyId.uuidString)
            .order("created_at", ascending: true)
            .execute()
        
        struct RedlineResponseExport: Codable {
            let situationId: String
            let situationText: String
            let redlineResponse: String
            let keywords: [String]
            let version: Int
            let createdAt: String
            
            enum CodingKeys: String, CodingKey {
                case situationId = "situation_id"
                case situationText = "situation_text"
                case redlineResponse = "full_response"
                case keywords
                case version
                case createdAt = "created_at"
            }
        }
        
        // Transform the data for export
        // This would need to be implemented based on the actual response structure
        let exportData: [RedlineResponseExport] = []
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try encoder.encode(exportData)
    }
    
    func importRedlineResponses(familyId: UUID, data: Data) async throws {
        struct RedlineResponseImport: Codable {
            let situationId: String
            let redlineResponse: String
            let keywords: [String]?
            let version: Int?
            
            enum CodingKeys: String, CodingKey {
                case situationId = "situation_id"
                case redlineResponse = "redline_response"
                case keywords
                case version
            }
        }
        
        let decoder = JSONDecoder()
        let imports = try decoder.decode([RedlineResponseImport].self, from: data)
        
        for importItem in imports {
            guard let situationId = UUID(uuidString: importItem.situationId) else {
                continue
            }
            
            let sections = ResponseSections(
                title: nil,
                steps: nil,
                tone: nil,
                keyPoints: nil,
                keywords: importItem.keywords
            )
            
            try await saveRedlineResponse(
                situationId: situationId,
                familyId: familyId,
                fullResponse: importItem.redlineResponse,
                responseSections: sections
            )
        }
    }
}

// MARK: - Error Types

enum RedlineResponseError: LocalizedError {
    case notFound
    case invalidVersion
    case importFailed(String)
    case keywordExtractionFailed
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Redline response not found"
        case .invalidVersion:
            return "Invalid version number"
        case .importFailed(let message):
            return "Import failed: \(message)"
        case .keywordExtractionFailed:
            return "Failed to extract keywords from redline response"
        }
    }
}