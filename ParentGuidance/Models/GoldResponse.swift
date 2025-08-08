import Foundation

// MARK: - Gold Response Models

struct GoldResponse: Identifiable, Codable {
    let id: UUID
    let situationId: UUID
    let familyId: UUID
    let version: Int
    let fullResponse: String
    let responseSections: ResponseSections?
    let authorId: UUID?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case situationId = "situation_id"
        case familyId = "family_id"
        case version
        case fullResponse = "full_response"
        case responseSections = "response_sections"
        case authorId = "author_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct RedlineResponse: Identifiable, Codable {
    let id: UUID
    let situationId: UUID
    let familyId: UUID
    let version: Int
    let fullResponse: String
    let responseSections: ResponseSections?
    let authorId: UUID?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case situationId = "situation_id"
        case familyId = "family_id"
        case version
        case fullResponse = "full_response"
        case responseSections = "response_sections"
        case authorId = "author_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ResponseSections: Codable {
    let title: String?
    let steps: [String]?
    let tone: String?
    let keyPoints: [String]?
    let keywords: [String]? // For redline responses
    
    enum CodingKeys: String, CodingKey {
        case title
        case steps
        case tone
        case keyPoints = "key_points"
        case keywords
    }
}

// MARK: - Experiment Models

struct ExperimentRun: Identifiable, Codable {
    let id: UUID
    let familyId: UUID
    let name: String
    let description: String?
    let config: ExperimentConfig
    let status: ExperimentStatus
    let runType: ExperimentRunType
    let dateRange: DateRange?
    let situationFilter: SituationFilter?
    let progress: ExperimentProgress
    let startedAt: Date?
    let completedAt: Date?
    let errorMessage: String?
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case name
        case description
        case config
        case status
        case runType = "run_type"
        case dateRange = "date_range"
        case situationFilter = "situation_filter"
        case progress
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case errorMessage = "error_message"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum ExperimentStatus: String, Codable {
    case queued
    case running
    case paused
    case completed
    case failed
}

enum ExperimentRunType: String, Codable {
    case manual
    case dynamicPrompting = "dynamic_prompting"
}

struct ExperimentConfig: Codable {
    let promptTemplates: [String: String]? // template_id -> full_text
    let modelProvider: String
    let temperature: Double?
    let topP: Double?
    let seed: Int?
    let useEdgeFunction: Bool
    let guidanceStyle: String
    let guidanceMode: String
    
    enum CodingKeys: String, CodingKey {
        case promptTemplates = "prompt_templates"
        case modelProvider = "model_provider"
        case temperature
        case topP = "top_p"
        case seed
        case useEdgeFunction = "use_edge_function"
        case guidanceStyle = "guidance_style"
        case guidanceMode = "guidance_mode"
    }
}

struct SituationFilter: Codable {
    let categories: [String]?
    let hasIncident: Bool?
    let textSearch: String?
    
    enum CodingKeys: String, CodingKey {
        case categories
        case hasIncident = "has_incident"
        case textSearch = "text_search"
    }
}

struct ExperimentProgress: Codable {
    var totalSituations: Int
    var processedSituations: Int
    var currentSituationId: UUID?
    var situationsWithGold: Int
    var situationsWithRedline: Int
    var averageCompositeScore: Double?
    
    enum CodingKeys: String, CodingKey {
        case totalSituations = "total_situations"
        case processedSituations = "processed_situations"
        case currentSituationId = "current_situation_id"
        case situationsWithGold = "situations_with_gold"
        case situationsWithRedline = "situations_with_redline"
        case averageCompositeScore = "average_composite_score"
    }
}

struct ExperimentScore: Identifiable, Codable {
    let id: UUID
    var experimentRunId: UUID
    var situationId: UUID
    var guidanceId: UUID
    let goldResponseId: UUID?
    let redlineResponseId: UUID?
    
    // Individual metric scores
    let semanticSimilarity: Double?
    let stringOverlap: Double?
    let styleToneScore: Double?
    
    // Redline penalties
    let redlineSimilarity: Double?
    let redlineKeywordHits: Int?
    let redlinePenalty: Double?
    
    // Composite score
    let compositeScore: Double
    let scoreWeights: ScoreWeights
    
    // Detailed comparison data
    let comparisonDetails: ComparisonDetails?
    
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case experimentRunId = "experiment_run_id"
        case situationId = "situation_id"
        case guidanceId = "guidance_id"
        case goldResponseId = "gold_response_id"
        case redlineResponseId = "redline_response_id"
        case semanticSimilarity = "semantic_similarity"
        case stringOverlap = "string_overlap"
        case styleToneScore = "style_tone_score"
        case redlineSimilarity = "redline_similarity"
        case redlineKeywordHits = "redline_keyword_hits"
        case redlinePenalty = "redline_penalty"
        case compositeScore = "composite_score"
        case scoreWeights = "score_weights"
        case comparisonDetails = "comparison_details"
        case createdAt = "created_at"
    }
}

struct ScoreWeights: Codable {
    let goldWeight: Double
    let redlineWeight: Double
    let semanticWeight: Double
    let stringOverlapWeight: Double
    let styleToneWeight: Double
    
    enum CodingKeys: String, CodingKey {
        case goldWeight = "gold_weight"
        case redlineWeight = "redline_weight"
        case semanticWeight = "semantic_weight"
        case stringOverlapWeight = "string_overlap_weight"
        case styleToneWeight = "style_tone_weight"
    }
    
    static let `default` = ScoreWeights(
        goldWeight: 0.7,
        redlineWeight: 0.3,
        semanticWeight: 0.4,
        stringOverlapWeight: 0.3,
        styleToneWeight: 0.3
    )
}

struct ComparisonDetails: Codable {
    let sectionScores: [String: Double]?
    let textDiffs: [String: String]?
    let matchedKeywords: [String]?
    let missedKeyPoints: [String]?
    
    enum CodingKeys: String, CodingKey {
        case sectionScores = "section_scores"
        case textDiffs = "text_diffs"
        case matchedKeywords = "matched_keywords"
        case missedKeyPoints = "missed_key_points"
    }
}