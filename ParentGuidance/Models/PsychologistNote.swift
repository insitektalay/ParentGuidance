//
//  PsychologistNote.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import Foundation

// MARK: - Note Types

enum PsychologistNoteType: String, CaseIterable, Codable, Identifiable {
    case context = "context"
    case traits = "traits"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .context:
            return "Child Context"
        case .traits:
            return "Key Insights"
        }
    }
    
    var iconName: String {
        switch self {
        case .context:
            return "person.crop.circle.fill"
        case .traits:
            return "brain.head.profile"
        }
    }
    
    var promptOperation: String {
        switch self {
        case .context:
            return "psychologists_note_context"
        case .traits:
            return "psychologists_note_traits"
        }
    }
}

// MARK: - PsychologistNote Model

struct PsychologistNote: Codable, Identifiable {
    let id: String
    let familyId: String
    let childId: String?
    let noteType: PsychologistNoteType
    let content: String
    let sourceDataSummary: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case childId = "child_id"
        case noteType = "note_type"
        case content
        case sourceDataSummary = "source_data_summary"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        familyId: String,
        childId: String? = nil,
        noteType: PsychologistNoteType,
        content: String,
        sourceDataSummary: String
    ) {
        self.id = UUID().uuidString
        self.familyId = familyId
        self.childId = childId
        self.noteType = noteType
        self.content = content
        self.sourceDataSummary = sourceDataSummary
        self.createdAt = ISO8601DateFormatter().string(from: Date())
        self.updatedAt = ISO8601DateFormatter().string(from: Date())
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        familyId = try container.decode(String.self, forKey: .familyId)
        childId = try container.decodeIfPresent(String.self, forKey: .childId)
        content = try container.decode(String.self, forKey: .content)
        sourceDataSummary = try container.decode(String.self, forKey: .sourceDataSummary)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        
        // Handle noteType with proper enum decoding
        if let noteTypeString = try? container.decode(String.self, forKey: .noteType),
           let noteTypeEnum = PsychologistNoteType(rawValue: noteTypeString) {
            noteType = noteTypeEnum
        } else {
            // Fallback to context if decoding fails
            noteType = .context
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(familyId, forKey: .familyId)
        try container.encodeIfPresent(childId, forKey: .childId)
        try container.encode(noteType.rawValue, forKey: .noteType)
        try container.encode(content, forKey: .content)
        try container.encode(sourceDataSummary, forKey: .sourceDataSummary)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - Convenience Extensions

extension PsychologistNote {
    var displayTitle: String {
        return noteType.displayName
    }
    
    var formattedCreatedDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return createdAt
    }
    
    var isRecent: Bool {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: createdAt) {
            let daysSinceCreation = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
            return daysSinceCreation <= 7
        }
        return false
    }
    
    var previewContent: String {
        let maxLength = 150
        if content.count <= maxLength {
            return content
        }
        let trimmed = String(content.prefix(maxLength))
        return trimmed + "..."
    }
}

// MARK: - Generation Request Models

struct PsychologistNoteRequest {
    let familyId: String
    let childId: String?
    let noteType: PsychologistNoteType
    let sourceData: String
    let sourceDataSummary: String
}

// MARK: - Error Types

enum PsychologistNoteError: LocalizedError {
    case noDataAvailable
    case generationFailed(String)
    case invalidResponse
    case databaseError(String)
    
    var errorDescription: String? {
        switch self {
        case .noDataAvailable:
            return "No data available to generate psychologist's note"
        case .generationFailed(let message):
            return "Failed to generate note: \(message)"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}