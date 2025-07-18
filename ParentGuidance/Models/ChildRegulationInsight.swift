//
//  ChildRegulationInsight.swift
//  ParentGuidance
//
//  Created by alex kerss on 18/07/2025.
//

import Foundation

// MARK: - Child Regulation Insight Model

struct ChildRegulationInsight: Codable, Identifiable {
    let id: UUID
    let familyId: String
    let childId: String?
    let situationId: String
    let category: RegulationCategory
    let content: String
    let insightResponseId: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case childId = "child_id"
        case situationId = "situation_id"
        case category
        case content
        case insightResponseId = "insight_response_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Regulation Category Enum

enum RegulationCategory: String, Codable, CaseIterable {
    case core = "Core"
    case adhd = "ADHD"
    case mildAutism = "Mild Autism"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Child Regulation Insights Response

struct ChildRegulationInsightsResponse: Codable {
    let core: [String]
    let adhd: [String]
    let mildAutism: [String]
    
    enum CodingKeys: String, CodingKey {
        case core = "Core"
        case adhd = "ADHD"
        case mildAutism = "Mild Autism"
    }
}

// MARK: - Convenience Extensions

extension ChildRegulationInsight {
    init(
        familyId: String,
        childId: String?,
        situationId: String,
        category: RegulationCategory,
        content: String,
        insightResponseId: String? = nil
    ) {
        self.id = UUID()
        self.familyId = familyId
        self.childId = childId
        self.situationId = situationId
        self.category = category
        self.content = content
        self.insightResponseId = insightResponseId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isNoPatternFound: Bool {
        return content.contains("No strong patterns found in this data")
    }
}

extension ChildRegulationInsightsResponse {
    func toBulletPoints(
        familyId: String,
        childId: String?,
        situationId: String,
        responseId: String? = nil
    ) -> [ChildRegulationInsight] {
        var insights: [ChildRegulationInsight] = []
        
        // Process Core insights
        for insight in core {
            insights.append(ChildRegulationInsight(
                familyId: familyId,
                childId: childId,
                situationId: situationId,
                category: .core,
                content: insight,
                insightResponseId: responseId
            ))
        }
        
        // Process ADHD insights
        for insight in adhd {
            insights.append(ChildRegulationInsight(
                familyId: familyId,
                childId: childId,
                situationId: situationId,
                category: .adhd,
                content: insight,
                insightResponseId: responseId
            ))
        }
        
        // Process Mild Autism insights
        for insight in mildAutism {
            insights.append(ChildRegulationInsight(
                familyId: familyId,
                childId: childId,
                situationId: situationId,
                category: .mildAutism,
                content: insight,
                insightResponseId: responseId
            ))
        }
        
        return insights
    }
}
