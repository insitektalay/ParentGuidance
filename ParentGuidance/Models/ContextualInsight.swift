//
//  ContextualInsight.swift
//  ParentGuidance
//
//  Created by alex kerss on 17/07/2025.
//

import Foundation

// MARK: - Context Categories

enum ContextCategory: String, CaseIterable, Codable, Identifiable {
    case familyContext = "family_context"
    case medicalHealth = "medical_health"
    case educationalAcademic = "educational_academic"
    case parentingApproaches = "parenting_approaches"
    case siblingDynamics = "sibling_dynamics"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .familyContext:
            return "Family Context"
        case .medicalHealth:
            return "Medical / Health"
        case .educationalAcademic:
            return "Educational / Academic"
        case .parentingApproaches:
            return "Parenting Approaches"
        case .siblingDynamics:
            return "Sibling Dynamics"
        }
    }
    
    var iconName: String {
        switch self {
        case .familyContext:
            return "house.fill"
        case .medicalHealth:
            return "cross.fill"
        case .educationalAcademic:
            return "book.fill"
        case .parentingApproaches:
            return "heart.fill"
        case .siblingDynamics:
            return "person.3.fill"
        }
    }
}


// MARK: - ContextualInsight Model

struct ContextualInsight: Codable {
    let id: String
    let familyId: String
    let childId: String?
    let category: ContextCategory
    let content: String
    /// References the situation this insight was extracted from.
    /// Can be nil for insights generated during bulk regeneration from multiple situations.
    let sourceSituationId: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case childId = "child_id"
        case category
        case content
        case sourceSituationId = "source_situation_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        familyId: String,
        childId: String? = nil,
        category: ContextCategory,
        content: String,
        sourceSituationId: String? = nil
    ) {
        self.id = UUID().uuidString
        self.familyId = familyId
        self.childId = childId
        self.category = category
        self.content = content
        self.sourceSituationId = sourceSituationId
        self.createdAt = ISO8601DateFormatter().string(from: Date())
        self.updatedAt = ISO8601DateFormatter().string(from: Date())
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        familyId = try container.decode(String.self, forKey: .familyId)
        childId = try container.decodeIfPresent(String.self, forKey: .childId)
        content = try container.decode(String.self, forKey: .content)
        sourceSituationId = try container.decodeIfPresent(String.self, forKey: .sourceSituationId)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        
        // Handle category with proper enum decoding
        if let categoryString = try? container.decode(String.self, forKey: .category),
           let categoryEnum = ContextCategory(rawValue: categoryString) {
            category = categoryEnum
        } else {
            // Fallback to familyContext if decoding fails
            category = .familyContext
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(familyId, forKey: .familyId)
        try container.encodeIfPresent(childId, forKey: .childId)
        try container.encode(category.rawValue, forKey: .category)
        try container.encode(content, forKey: .content)
        try container.encode(sourceSituationId, forKey: .sourceSituationId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - Convenience Extensions

extension ContextualInsight {
    var displayTitle: String {
        return category.displayName
    }
}

// MARK: - Helper Functions

extension ContextCategory {
    static func from(apiResponseKey key: String) -> ContextCategory? {
        switch key.lowercased() {
        case "family context":
            return .familyContext
        case "medical / health":
            return .medicalHealth
        case "educational / academic":
            return .educationalAcademic
        case "parenting approaches":
            return .parentingApproaches
        case "sibling dynamics":
            return .siblingDynamics
        default:
            return nil
        }
    }
}

