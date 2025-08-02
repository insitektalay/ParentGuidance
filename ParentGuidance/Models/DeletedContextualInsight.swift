//
//  DeletedContextualInsight.swift
//  ParentGuidance
//
//  Created by alex kerss on 30/07/2025.
//

import Foundation

// MARK: - Deleted Contextual Insight Model

struct DeletedContextualInsight: Codable, Identifiable {
    let id: UUID
    let originalInsightId: String
    let familyId: String
    let childId: String?
    let category: ContextCategory
    let content: String
    let sourceSituationId: String?
    let deletedAt: Date
    let deletedReason: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case originalInsightId = "original_insight_id"
        case familyId = "family_id"
        case childId = "child_id"
        case category
        case content
        case sourceSituationId = "source_situation_id"
        case deletedAt = "deleted_at"
        case deletedReason = "deleted_reason"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Convenience Extensions

extension DeletedContextualInsight {
    init(
        from insight: ContextualInsight,
        deletedReason: String? = nil
    ) {
        self.id = UUID()
        self.originalInsightId = insight.id
        self.familyId = insight.familyId
        self.childId = insight.childId
        self.category = insight.category
        self.content = insight.content
        self.sourceSituationId = insight.sourceSituationId
        self.deletedAt = Date()
        self.deletedReason = deletedReason
        self.createdAt = insight.createdAt
        self.updatedAt = insight.updatedAt
    }
    
    func toContextualInsight() -> ContextualInsight {
        return ContextualInsight(
            familyId: familyId,
            childId: childId,
            category: category,
            content: content,
            sourceSituationId: sourceSituationId
        )
    }
}