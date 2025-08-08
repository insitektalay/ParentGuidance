import Foundation

// MARK: - Prompt Block Registry Models

struct PromptBlock: Identifiable, Codable {
    let id: UUID
    var name: String
    var version: String
    var paramsJson: [String: AnyCodable]
    var enabled: Bool
    var changeLog: String?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case version
        case paramsJson = "params_json"
        case enabled
        case changeLog = "change_log"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Cohort mapping (issue×age band)
struct BlockCohortPin: Identifiable, Codable {
    let id: UUID
    let blockId: UUID
    let issueType: String
    let ageBand: String
    let enabled: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case blockId = "block_id"
        case issueType = "issue_type"
        case ageBand = "age_band"
        case enabled
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Lightweight AnyCodable for params
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) { value = int; return }
        if let dbl = try? container.decode(Double.self) { value = dbl; return }
        if let bool = try? container.decode(Bool.self) { value = bool; return }
        if let str = try? container.decode(String.self) { value = str; return }
        if let dict = try? container.decode([String: AnyCodable].self) { value = dict; return }
        if let arr = try? container.decode([AnyCodable].self) { value = arr; return }
        value = NSNull()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let int as Int: try container.encode(int)
        case let dbl as Double: try container.encode(dbl)
        case let bool as Bool: try container.encode(bool)
        case let str as String: try container.encode(str)
        case let dict as [String: AnyCodable]: try container.encode(dict)
        case let arr as [AnyCodable]: try container.encode(arr)
        default: try container.encodeNil()
        }
    }
}


