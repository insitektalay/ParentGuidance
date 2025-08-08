import Foundation

// MARK: - Regen Run Models

struct RegenRun: Identifiable, Codable {
    let id: UUID
    let familyId: UUID
    let status: RegenRunStatus
    let config: RegenConfig
    let progress: RegenProgress
    let startedAt: Date
    let completedAt: Date?
    let errorMessage: String?
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case status
        case config
        case progress
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case errorMessage = "error_message"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum RegenRunStatus: String, Codable {
    case running
    case paused
    case completed
    case failed
}

struct RegenConfig: Codable {
    var modelProvider: String // openai/anthropic/xai/google
    var guidanceStyle: String // warm_practical/analytical_scientific
    var guidanceMode: String // fixed/dynamic
    var similarityThreshold: Double // 0.8 default
    var familyFilter: String? // specific family ID or "all"
    var dateRange: DateRange?
    var determinismSeed: Int?
    var experimentRunId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case modelProvider = "model_provider"
        case guidanceStyle = "guidance_style"
        case guidanceMode = "guidance_mode"
        case similarityThreshold = "similarity_threshold"
        case familyFilter = "family_filter"
        case dateRange = "date_range"
        case determinismSeed = "determinism_seed"
        case experimentRunId = "experiment_run_id"
    }
}

struct DateRange: Codable {
    let start: Date
    let end: Date
}

struct RegenProgress: Codable {
    var totalSituations: Int
    var processedSituations: Int
    var currentSituationId: UUID?
    var currentSituationIndex: Int
    var guidanceGenerated: Int
    var insightsExtracted: Int
    var apiCallsMade: Int
    var errors: [ProcessingError]
    
    enum CodingKeys: String, CodingKey {
        case totalSituations = "total_situations"
        case processedSituations = "processed_situations"
        case currentSituationId = "current_situation_id"
        case currentSituationIndex = "current_situation_index"
        case guidanceGenerated = "guidance_generated"
        case insightsExtracted = "insights_extracted"
        case apiCallsMade = "api_calls_made"
        case errors
    }
    
    var progressPercentage: Double {
        guard totalSituations > 0 else { return 0 }
        return Double(processedSituations) / Double(totalSituations) * 100
    }
}

struct ProcessingError: Codable {
    let situationId: UUID
    let errorType: String
    let message: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case situationId = "situation_id"
        case errorType = "error_type"
        case message
        case timestamp
    }
}