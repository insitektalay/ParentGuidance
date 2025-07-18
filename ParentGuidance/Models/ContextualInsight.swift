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
    case provenRegulationTools = "proven_regulation_tools"
    case medicalHealth = "medical_health"
    case educationalAcademic = "educational_academic"
    case peerSocial = "peer_social"
    case behavioralPatterns = "behavioral_patterns"
    case dailyLifePractical = "daily_life_practical"
    case temporalTiming = "temporal_timing"
    case environmentalTechTriggers = "environmental_tech_triggers"
    case parentingApproaches = "parenting_approaches"
    case siblingDynamics = "sibling_dynamics"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .familyContext:
            return "Family Context"
        case .provenRegulationTools:
            return "Proven Regulation Tools"
        case .medicalHealth:
            return "Medical / Health"
        case .educationalAcademic:
            return "Educational / Academic"
        case .peerSocial:
            return "Peer / Social"
        case .behavioralPatterns:
            return "Behavioral Patterns"
        case .dailyLifePractical:
            return "Daily Life / Practical"
        case .temporalTiming:
            return "Temporal / Timing"
        case .environmentalTechTriggers:
            return "Environmental & Tech Triggers"
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
        case .provenRegulationTools:
            return "hammer.fill"
        case .medicalHealth:
            return "cross.fill"
        case .educationalAcademic:
            return "book.fill"
        case .peerSocial:
            return "person.2.fill"
        case .behavioralPatterns:
            return "chart.line.uptrend.xyaxis"
        case .dailyLifePractical:
            return "clock.fill"
        case .temporalTiming:
            return "calendar"
        case .environmentalTechTriggers:
            return "speaker.wave.2.fill"
        case .parentingApproaches:
            return "heart.fill"
        case .siblingDynamics:
            return "person.3.fill"
        }
    }
}

enum ContextSubcategory: String, CaseIterable, Codable {
    // Proven Regulation Tools subcategories
    case physicalSensory = "physical_sensory"
    case environmental = "environmental"
    case routinePredictable = "routine_predictable"
    case keySuccessPatterns = "key_success_patterns"
    case timingNotes = "timing_notes"
    
    var displayName: String {
        switch self {
        case .physicalSensory:
            return "Physical/Sensory"
        case .environmental:
            return "Environmental"
        case .routinePredictable:
            return "Routine/Predictable"
        case .keySuccessPatterns:
            return "Key Success Patterns"
        case .timingNotes:
            return "Timing Notes"
        }
    }
    
    var parentCategory: ContextCategory {
        return .provenRegulationTools
    }
}

// MARK: - ContextualInsight Model

struct ContextualInsight: Codable {
    let id: String
    let familyId: String
    let childId: String?
    let category: ContextCategory
    let subcategory: ContextSubcategory?
    let content: String
    let sourceSituationId: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case childId = "child_id"
        case category
        case subcategory
        case content
        case sourceSituationId = "source_situation_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        familyId: String,
        childId: String? = nil,
        category: ContextCategory,
        subcategory: ContextSubcategory? = nil,
        content: String,
        sourceSituationId: String
    ) {
        self.id = UUID().uuidString
        self.familyId = familyId
        self.childId = childId
        self.category = category
        self.subcategory = subcategory
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
        sourceSituationId = try container.decode(String.self, forKey: .sourceSituationId)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        
        // Handle category and subcategory with proper enum decoding
        if let categoryString = try? container.decode(String.self, forKey: .category),
           let categoryEnum = ContextCategory(rawValue: categoryString) {
            category = categoryEnum
        } else {
            // Fallback to familyContext if decoding fails
            category = .familyContext
        }
        
        if let subcategoryString = try? container.decode(String.self, forKey: .subcategory),
           let subcategoryEnum = ContextSubcategory(rawValue: subcategoryString) {
            subcategory = subcategoryEnum
        } else {
            subcategory = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(familyId, forKey: .familyId)
        try container.encodeIfPresent(childId, forKey: .childId)
        try container.encode(category.rawValue, forKey: .category)
        try container.encodeIfPresent(subcategory?.rawValue, forKey: .subcategory)
        try container.encode(content, forKey: .content)
        try container.encode(sourceSituationId, forKey: .sourceSituationId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - Convenience Extensions

extension ContextualInsight {
    var displayTitle: String {
        if let subcategory = subcategory {
            return "\(category.displayName) - \(subcategory.displayName)"
        }
        return category.displayName
    }
    
    var isRegulationTool: Bool {
        return category == .provenRegulationTools
    }
    
    var hasSubcategory: Bool {
        return subcategory != nil
    }
}

// MARK: - Helper Functions

extension ContextCategory {
    static func from(apiResponseKey key: String) -> ContextCategory? {
        switch key.lowercased() {
        case "family context":
            return .familyContext
        case "proven regulation tools – physical/sensory":
            return .provenRegulationTools
        case "proven regulation tools – environmental":
            return .provenRegulationTools
        case "proven regulation tools – routine/predictable":
            return .provenRegulationTools
        case "proven regulation tools – key success patterns":
            return .provenRegulationTools
        case "proven regulation tools – timing notes":
            return .provenRegulationTools
        case "medical / health":
            return .medicalHealth
        case "educational / academic":
            return .educationalAcademic
        case "peer / social":
            return .peerSocial
        case "behavioral patterns":
            return .behavioralPatterns
        case "daily life / practical":
            return .dailyLifePractical
        case "temporal / timing":
            return .temporalTiming
        case "environmental & tech triggers":
            return .environmentalTechTriggers
        case "parenting approaches":
            return .parentingApproaches
        case "sibling dynamics":
            return .siblingDynamics
        default:
            return nil
        }
    }
}

extension ContextSubcategory {
    static func from(apiResponseKey key: String) -> ContextSubcategory? {
        switch key.lowercased() {
        case "proven regulation tools – physical/sensory":
            return .physicalSensory
        case "proven regulation tools – environmental":
            return .environmental
        case "proven regulation tools – routine/predictable":
            return .routinePredictable
        case "proven regulation tools – key success patterns":
            return .keySuccessPatterns
        case "proven regulation tools – timing notes":
            return .timingNotes
        default:
            return nil
        }
    }
}