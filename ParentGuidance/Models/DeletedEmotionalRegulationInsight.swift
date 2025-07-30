//
//  DeletedEmotionalRegulationInsight.swift
//  ParentGuidance
//
//  Created by alex kerss on 30/07/2025.
//

import Foundation

// MARK: - Deleted Emotional Regulation Insight Model

struct DeletedEmotionalRegulationInsight: Codable, Identifiable {
    let id: UUID
    let originalInsightId: UUID?
    let familyId: String
    let childId: String?
    let situationId: String
    let content: String
    let deletedAt: Date
    let deletedReason: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case originalInsightId = "original_insight_id"
        case familyId = "family_id"
        case childId = "child_id"
        case situationId = "situation_id"
        case content
        case deletedAt = "deleted_at"
        case deletedReason = "deleted_reason"
    }
}

// MARK: - Convenience Extensions

extension DeletedEmotionalRegulationInsight {
    init(
        from insight: ChildRegulationInsight,
        deletedReason: String? = nil
    ) {
        self.id = UUID()
        self.originalInsightId = insight.id
        self.familyId = insight.familyId
        self.childId = insight.childId
        self.situationId = insight.situationId
        self.content = insight.content
        self.deletedAt = Date()
        self.deletedReason = deletedReason
    }
    
    func toChildRegulationInsight() -> ChildRegulationInsight {
        return ChildRegulationInsight(
            familyId: familyId,
            childId: childId,
            situationId: situationId,
            category: .core, // Emotional Self-Regulation maps to .core
            content: content
        )
    }
}