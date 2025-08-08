import Foundation

// MARK: - Resolved Policy Models (Serve-time configuration injected into orchestration)

struct ResolvedPolicy: Codable {
    let modelProvider: String
    let temperature: Double?
    let topP: Double?
    let seed: Int?
    let guidance: GuidanceParams?
    let promptBlocks: PromptBlocks
    
    enum CodingKeys: String, CodingKey {
        case modelProvider = "model_provider"
        case temperature
        case topP = "top_p"
        case seed
        case guidance
        case promptBlocks = "prompt_blocks"
    }
}

struct PromptBlocks: Codable {
    let similarCase: SimilarCaseParams?
    let actionTemplate: ActionTemplateParams?
    let contextExtraction: ContextExtractionParams?
    let relevantInsights: ToggleBlock?
    let analysis: AnalysisParams?
    let translation: TranslationParams?
    
    enum CodingKeys: String, CodingKey {
        case similarCase = "similar_case"
        case actionTemplate = "action_template"
        case contextExtraction = "context_extraction"
        case relevantInsights = "relevant_insights"
        case analysis
        case translation
    }
}

struct SimilarCaseParams: Codable {
    let k: Int?
    let recencyDays: Int?
    let minSim: Double?
    let issueFilter: Bool?
    
    enum CodingKeys: String, CodingKey {
        case k
        case recencyDays = "recency_days"
        case minSim = "min_sim"
        case issueFilter = "issue_filter"
    }
}

struct ActionTemplateParams: Codable {
    let steps: Int?
    let includeIfThen: Bool?
    let includeStopClause: Bool?
    
    enum CodingKeys: String, CodingKey {
        case steps
        case includeIfThen = "include_if_then"
        case includeStopClause = "include_stop_clause"
    }
}

struct ContextExtractionParams: Codable {
    let enabled: Bool
    let provider: String // "edge" | "direct"
    let batchSize: Int?
    let delayMs: Int?
    let similarityThreshold: Double?
    let language: String? // "auto" | <code>
    
    enum CodingKeys: String, CodingKey {
        case enabled
        case provider
        case batchSize = "batch_size"
        case delayMs = "delay_ms"
        case similarityThreshold = "similarity_threshold"
        case language
    }
}

struct ToggleBlock: Codable {
    let enabled: Bool
}

struct AnalysisParams: Codable {
    let enabled: Bool
    let provider: String? // "edge" | "direct"
    let promptVersion: String?
    
    enum CodingKeys: String, CodingKey {
        case enabled
        case provider
        case promptVersion = "prompt_version"
    }
}

struct TranslationParams: Codable {
    let enabled: Bool
    let targetLanguage: String?
    let smartOnDemand: Bool?
    
    enum CodingKeys: String, CodingKey {
        case enabled
        case targetLanguage = "target_language"
        case smartOnDemand = "smart_on_demand"
    }
}

struct GuidanceParams: Codable {
    let useFunctionCalling: Bool?
    let structureMode: String?
    let guidanceStyle: String?
    let situationType: String?
    
    enum CodingKeys: String, CodingKey {
        case useFunctionCalling = "use_function_calling"
        case structureMode = "structure_mode"
        case guidanceStyle = "guidance_style"
        case situationType = "situation_type"
    }
}


