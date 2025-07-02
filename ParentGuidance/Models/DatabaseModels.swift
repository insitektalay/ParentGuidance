import Foundation

// MARK: - Situation Model
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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Initializer for creating new situations
    init(
        familyId: String?,
        childId: String?,
        title: String,
        description: String,
        situationType: String = "one_time"
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
        self.createdAt = ISO8601DateFormatter().string(from: Date())
        self.updatedAt = ISO8601DateFormatter().string(from: Date())
    }
    
    // Custom decoder to handle JSONB fields
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
        
        // Handle JSONB fields - decode as nil for now
        followUpResponses = nil
        timingContext = nil
        environmentalContext = nil
        emotionalContext = nil
    }
}

// MARK: - Guidance Model
struct Guidance: Codable {
    let id: String
    let situationId: String
    let situationCategory: String?
    let content: String
    let foundationToolEnhanced: Bool
    let activeFrameworks: [String: Any]?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case situationId = "situation_id"
        case situationCategory = "situation_category"
        case content
        case foundationToolEnhanced = "foundation_tool_enhanced"
        case activeFrameworks = "active_frameworks"
        case createdAt = "created_at"
    }
    
    // Initializer for creating new guidance
    init(
        situationId: String,
        content: String,
        situationCategory: String? = nil,
        foundationToolEnhanced: Bool = false
    ) {
        self.id = UUID().uuidString
        self.situationId = situationId
        self.situationCategory = situationCategory
        self.content = content
        self.foundationToolEnhanced = foundationToolEnhanced
        self.activeFrameworks = nil
        self.createdAt = ISO8601DateFormatter().string(from: Date())
    }
    
    // Custom decoder to handle JSONB fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        situationId = try container.decode(String.self, forKey: .situationId)
        situationCategory = try container.decodeIfPresent(String.self, forKey: .situationCategory)
        content = try container.decode(String.self, forKey: .content)
        foundationToolEnhanced = try container.decode(Bool.self, forKey: .foundationToolEnhanced)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        
        // Handle JSONB field - decode as nil for now
        activeFrameworks = nil
    }
}

// MARK: - Conversation Pair (for UI convenience)
struct ConversationPair {
    let situation: Situation
    let guidance: Guidance
}