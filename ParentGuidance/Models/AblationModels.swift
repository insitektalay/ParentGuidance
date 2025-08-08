import Foundation

// MARK: - Ablation / Planner / Ensemble Models

struct AblationRun: Identifiable, Codable {
    let id: UUID
    let experimentRunId: UUID
    let blockName: String
    let paramKey: String
    let controlValue: String
    let testValue: String
    let upliftJson: [String: Double] // meanDelta, pValue, ciLow, ciHigh
    let sliceDef: [String: String]?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case experimentRunId = "experiment_run_id"
        case blockName = "block_name"
        case paramKey = "param_key"
        case controlValue = "control_value"
        case testValue = "test_value"
        case upliftJson = "uplift_json"
        case sliceDef = "slice_def"
        case createdAt = "created_at"
    }
}

struct BlockPlan: Identifiable, Codable {
    let id: UUID
    let ablationRunId: UUID
    let planText: String
    let paramsJson: [String: AnyCodable]
    let judgeSummaryJson: [String: AnyCodable]?
    let picked: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ablationRunId = "ablation_run_id"
        case planText = "plan_text"
        case paramsJson = "params_json"
        case judgeSummaryJson = "judge_summary_json"
        case picked
        case createdAt = "created_at"
    }
}

struct EnsembleRecord: Identifiable, Codable {
    let id: UUID
    let experimentRunId: UUID
    let mode: String
    let componentsJson: [String: AnyCodable]
    let judgeSummaryJson: [String: AnyCodable]?
    let chosen: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case experimentRunId = "experiment_run_id"
        case mode
        case componentsJson = "components_json"
        case judgeSummaryJson = "judge_summary_json"
        case chosen
        case createdAt = "created_at"
    }
}


