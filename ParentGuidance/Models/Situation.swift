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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        familyId: String?,
        childId: String?,
        title: String,
        description: String,
        situationType: String = "one_time",
        isFavorited: Bool = false
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
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        // Handle JSONB fields - encode as nil for now
        try container.encodeIfPresent(followUpResponses as? [String: String], forKey: .followUpResponses)
        try container.encodeIfPresent(timingContext as? [String: String], forKey: .timingContext)
        try container.encodeIfPresent(environmentalContext as? [String: String], forKey: .environmentalContext)
        try container.encodeIfPresent(emotionalContext as? [String: String], forKey: .emotionalContext)
    }
}
