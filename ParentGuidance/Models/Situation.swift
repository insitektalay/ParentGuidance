//
//  Situation.swift
//  ParentGuidance
//
//  Created by alex kerss on 06/07/2025.
//

import Foundation

// MARK: - Database Models
struct Situation: Codable {
    let id: String
    let familyId: String?
    let childId: String?
    let title: String
    let description: String
    let followUpResponses: [String: Any]?
    let situationType: String
    let timingContext: [String: Any]?
    let environmentalContext: [String: Any]?
    let emotionalContext: [String: Any]?
    let isFavorited: Bool
    let category: String?
    let isIncident: Bool
    let originalLanguage: String
    let secondaryTitle: String?
    let secondaryDescription: String?
    let secondaryLanguage: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case childId = "child_id"
        case title
        case description
        case followUpResponses = "follow_up_responses"
        case situationType = "situation_type"
        case timingContext = "timing_context"
        case environmentalContext = "environmental_context"
        case emotionalContext = "emotional_context"
        case isFavorited = "is_favorited"
        case category
        case isIncident = "is_incident"
        case originalLanguage = "original_language"
        case secondaryTitle = "secondary_title"
        case secondaryDescription = "secondary_description"
        case secondaryLanguage = "secondary_language"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        familyId: String?,
        childId: String?,
        title: String,
        description: String,
        situationType: String = "one_time",
        isFavorited: Bool = false,
        category: String? = nil,
        isIncident: Bool = false,
        originalLanguage: String = "en"
    ) {
        self.id = UUID().uuidString
        self.familyId = familyId
        self.childId = childId
        self.title = title
        self.description = description
        self.followUpResponses = nil
        self.situationType = situationType
        self.timingContext = nil
        self.environmentalContext = nil
        self.emotionalContext = nil
        self.isFavorited = isFavorited
        self.category = category
        self.isIncident = isIncident
        self.originalLanguage = originalLanguage
        self.secondaryTitle = nil
        self.secondaryDescription = nil
        self.secondaryLanguage = nil
        self.createdAt = ISO8601DateFormatter().string(from: Date())
        self.updatedAt = ISO8601DateFormatter().string(from: Date())
    }
    
    // Copy initializer that preserves all original data
    init(copying situation: Situation, isFavorited: Bool) {
        self.id = situation.id
        self.familyId = situation.familyId
        self.childId = situation.childId
        self.title = situation.title
        self.description = situation.description
        self.followUpResponses = situation.followUpResponses
        self.situationType = situation.situationType
        self.timingContext = situation.timingContext
        self.environmentalContext = situation.environmentalContext
        self.emotionalContext = situation.emotionalContext
        self.isFavorited = isFavorited // Only this changes
        self.category = situation.category // Preserve original category
        self.isIncident = situation.isIncident // Preserve original incident status
        self.originalLanguage = situation.originalLanguage // Preserve original language
        self.secondaryTitle = situation.secondaryTitle // Preserve secondary content
        self.secondaryDescription = situation.secondaryDescription
        self.secondaryLanguage = situation.secondaryLanguage
        self.createdAt = situation.createdAt // Preserve original date
        self.updatedAt = situation.updatedAt // Preserve original date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        familyId = try container.decodeIfPresent(String.self, forKey: .familyId)
        childId = try container.decodeIfPresent(String.self, forKey: .childId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        situationType = try container.decode(String.self, forKey: .situationType)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        
        // Handle favorite status with default false for backwards compatibility
        isFavorited = (try? container.decode(Bool.self, forKey: .isFavorited)) ?? false
        
        // Handle analysis fields with defaults for backwards compatibility
        category = try? container.decodeIfPresent(String.self, forKey: .category)
        isIncident = (try? container.decode(Bool.self, forKey: .isIncident)) ?? false
        
        // Handle language fields with defaults
        originalLanguage = (try? container.decode(String.self, forKey: .originalLanguage)) ?? "en"
        secondaryTitle = try? container.decodeIfPresent(String.self, forKey: .secondaryTitle)
        secondaryDescription = try? container.decodeIfPresent(String.self, forKey: .secondaryDescription)
        secondaryLanguage = try? container.decodeIfPresent(String.self, forKey: .secondaryLanguage)
        
        // Handle JSONB fields - decode as nil for now
        followUpResponses = nil
        timingContext = nil
        environmentalContext = nil
        emotionalContext = nil
    }
    
    // Custom encoder to handle JSONB fields
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(familyId, forKey: .familyId)
        try container.encodeIfPresent(childId, forKey: .childId)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(situationType, forKey: .situationType)
        try container.encode(isFavorited, forKey: .isFavorited)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encode(isIncident, forKey: .isIncident)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        // Handle JSONB fields - encode as nil for now
        try container.encodeIfPresent(followUpResponses as? [String: String], forKey: .followUpResponses)
        try container.encodeIfPresent(timingContext as? [String: String], forKey: .timingContext)
        try container.encodeIfPresent(environmentalContext as? [String: String], forKey: .environmentalContext)
        try container.encodeIfPresent(emotionalContext as? [String: String], forKey: .emotionalContext)
    }
    
    // MARK: - Language Support Methods
    
    /// Get the title in the user's preferred language
    func getTitle(for userLanguage: String) -> String {
        if userLanguage == originalLanguage {
            return title
        } else if userLanguage == secondaryLanguage, let secondaryTitle = secondaryTitle {
            return secondaryTitle
        } else {
            return title // Fallback to original
        }
    }
    
    /// Get the description in the user's preferred language
    func getDescription(for userLanguage: String) -> String {
        if userLanguage == originalLanguage {
            return description
        } else if userLanguage == secondaryLanguage, let secondaryDescription = secondaryDescription {
            return secondaryDescription
        } else {
            return description // Fallback to original
        }
    }
    
    /// Check if this situation has content in the specified language
    func hasContentInLanguage(_ language: String) -> Bool {
        return originalLanguage == language || secondaryLanguage == language
    }
}
