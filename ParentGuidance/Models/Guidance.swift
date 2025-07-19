//
//  Guidance.swift
//  ParentGuidance
//
//  Created by alex kerss on 06/07/2025.
//

import Foundation

// MARK: - Guidance Model
struct Guidance: Codable {
    let id: String
    let situationId: String
    let content: String
    let category: String?
    let originalLanguage: String
    let secondaryContent: String?
    let secondaryLanguage: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case situationId = "situation_id"
        case content
        case category
        case originalLanguage = "original_language"
        case secondaryContent = "secondary_content"
        case secondaryLanguage = "secondary_language"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Standard initializer for creating new guidance (backwards compatible)
    init(id: String = UUID().uuidString, situationId: String, content: String, category: String? = nil, createdAt: String? = nil, updatedAt: String? = nil, originalLanguage: String = "en") {
        self.id = id
        self.situationId = situationId
        self.content = content
        self.category = category
        self.originalLanguage = originalLanguage
        self.secondaryContent = nil
        self.secondaryLanguage = nil
        
        let currentDate = ISO8601DateFormatter().string(from: Date())
        self.createdAt = createdAt ?? currentDate
        self.updatedAt = updatedAt ?? currentDate
    }
    
    // Custom decoder to handle new language fields with defaults
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        situationId = try container.decode(String.self, forKey: .situationId)
        content = try container.decode(String.self, forKey: .content)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        
        // Handle language fields with defaults for backwards compatibility
        originalLanguage = (try? container.decode(String.self, forKey: .originalLanguage)) ?? "en"
        secondaryContent = try? container.decodeIfPresent(String.self, forKey: .secondaryContent)
        secondaryLanguage = try? container.decodeIfPresent(String.self, forKey: .secondaryLanguage)
    }
    
    // MARK: - Language Support Methods
    
    /// Get the content in the user's preferred language
    func getContent(for userLanguage: String) -> String {
        if userLanguage == originalLanguage {
            return content
        } else if userLanguage == secondaryLanguage, let secondaryContent = secondaryContent {
            return secondaryContent
        } else {
            return content // Fallback to original
        }
    }
    
    /// Check if this guidance has content in the specified language
    func hasContentInLanguage(_ language: String) -> Bool {
        return originalLanguage == language || secondaryLanguage == language
    }
}
