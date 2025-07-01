import Foundation

struct Child: Codable, Identifiable {
    let id: String
    let familyId: String?
    let name: String?
    let age: Int?
    let pronouns: String?
    let personalityTraits: String?
    let currentChallenges: String?
    let strengths: String?
    let goals: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case name
        case age
        case pronouns
        case personalityTraits = "personality_traits"
        case currentChallenges = "current_challenges"
        case strengths
        case goals
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Custom init for creating new children
    init(familyId: String, name: String, age: Int? = nil, pronouns: String? = nil) {
        self.id = UUID().uuidString
        self.familyId = familyId
        self.name = name
        self.age = age
        self.pronouns = pronouns
        self.personalityTraits = nil
        self.currentChallenges = nil
        self.strengths = nil
        self.goals = nil
        self.createdAt = ISO8601DateFormatter().string(from: Date())
        self.updatedAt = ISO8601DateFormatter().string(from: Date())
    }
    
}