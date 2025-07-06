//
//  Guidance.swift
//  ParentGuidance
//
//  Created by alex kerss on 06/07/2025.
//

import Foundation

// MARK: - Guidance Model
struct Guidance: Codable {
    let id: String
    let situationId: String
    let content: String
    let category: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case situationId = "situation_id"
        case content
        case category
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
