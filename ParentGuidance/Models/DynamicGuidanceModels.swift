//
//  DynamicGuidanceModels.swift
//  ParentGuidance
//
//  Created by alex kerss on 16/07/2025.
//

import Foundation

// MARK: - Dynamic Guidance Response
struct DynamicGuidanceResponse {
    let title: String
    let sections: [GuidanceSection]
    let totalSections: Int
    
    init(title: String, sections: [GuidanceSection]) {
        self.title = title
        self.sections = sections.sorted { $0.order < $1.order }
        self.totalSections = sections.count
    }
}

// MARK: - Guidance Section
struct GuidanceSection {
    let id: String
    let title: String
    let content: String
    let order: Int
    
    init(title: String, content: String, order: Int) {
        self.id = UUID().uuidString
        self.title = title
        self.content = content
        self.order = order
    }
}

// MARK: - Unified Protocol
protocol GuidanceResponseProtocol {
    var title: String { get }
    var displaySections: [GuidanceSection] { get }
    var sectionCount: Int { get }
}

// MARK: - Protocol Extensions
extension DynamicGuidanceResponse: GuidanceResponseProtocol {
    var displaySections: [GuidanceSection] { sections }
    var sectionCount: Int { totalSections }
}

extension GuidanceResponse: GuidanceResponseProtocol {
    var displaySections: [GuidanceSection] {
        [
            GuidanceSection(title: "Situation", content: situation, order: 1),
            GuidanceSection(title: "Analysis", content: analysis, order: 2),
            GuidanceSection(title: "Action Steps", content: actionSteps, order: 3),
            GuidanceSection(title: "Phrases to Try", content: phrasesToTry, order: 4),
            GuidanceSection(title: "Quick Comebacks", content: quickComebacks, order: 5),
            GuidanceSection(title: "Support", content: support, order: 6)
        ]
    }
    var sectionCount: Int { 6 }
}
