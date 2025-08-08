import Foundation
import Supabase

@MainActor
class ScoringService: ObservableObject {
    static let shared = ScoringService()
    
    private let supabaseManager = SupabaseManager.shared
    private let redlinePenaltyCalculator = RedlinePenaltyCalculator()
    
    private init() {}
    
    // MARK: - Experiment Scoring
    
    func scoreGuidance(
        guidanceText: String,
        goldResponse: GoldResponse?,
        redlineResponse: RedlineResponse?
    ) async throws -> ExperimentScore {
        // Create temporary objects to use the existing scoring logic
        let tempSituation = Situation(
            familyId: nil,
            childId: nil,
            title: "Temp Situation",
            description: "Temporary situation for scoring",
            situationType: "one_time",
            isFavorited: false,
            category: nil,
            isIncident: false,
            originalLanguage: "en"
        )
        
        let tempGuidance = Guidance(
            situationId: tempSituation.id,
            content: guidanceText,
            category: nil,
            originalLanguage: "en"
        )
        
        return try await scoreSingleSituation(
            experimentRunId: UUID(), // Will be updated by caller
            situation: tempSituation,
            guidance: tempGuidance,
            goldResponse: goldResponse,
            redlineResponse: redlineResponse
        )
    }
    
    func scoreExperimentRun(
        experimentRunId: UUID,
        situations: [Situation],
        guidance: [Guidance],
        goldResponses: [GoldResponse],
        redlineResponses: [RedlineResponse]
    ) async throws -> [ExperimentScore] {
        var scores: [ExperimentScore] = []
        
        for situation in situations {
            guard let situationGuidance = guidance.first(where: { $0.situationId == situation.id }) else {
                continue
            }
            
            let goldResponse = goldResponses.first(where: { $0.situationId.uuidString == situation.id })
            let redlineResponse = redlineResponses.first(where: { $0.situationId.uuidString == situation.id })
            
            let score = try await scoreSingleSituation(
                experimentRunId: experimentRunId,
                situation: situation,
                guidance: situationGuidance,
                goldResponse: goldResponse,
                redlineResponse: redlineResponse
            )
            
            scores.append(score)
        }
        
        return scores
    }
    
    private func scoreSingleSituation(
        experimentRunId: UUID,
        situation: Situation,
        guidance: Guidance,
        goldResponse: GoldResponse?,
        redlineResponse: RedlineResponse?
    ) async throws -> ExperimentScore {
        var semanticSimilarity: Double? = nil
        var stringOverlap: Double? = nil
        var styleToneScore: Double? = nil
        var redlineSimilarity: Double? = nil
        var redlineKeywordHits: Int = 0
        var redlinePenalty: Double = 0.0
        
        // Calculate gold alignment scores
        if let gold = goldResponse {
            semanticSimilarity = try await calculateSemanticSimilarity(
                text1: guidance.content,
                text2: gold.fullResponse
            )
            
            stringOverlap = calculateRougeL(
                reference: gold.fullResponse,
                candidate: guidance.content
            )
            
            styleToneScore = try await calculateStyleToneScore(
                guidance: guidance.content,
                goldResponse: gold.fullResponse
            )
        }
        
        // Calculate redline penalties
        if let redline = redlineResponse {
            let penalty = redlinePenaltyCalculator.calculateRedlinePenalty(
                output: guidance.content,
                redline: redline
            )
            
            redlineSimilarity = penalty.semanticProximity
            redlineKeywordHits = penalty.keywordHits
            redlinePenalty = penalty.totalPenalty
        }
        
        // Calculate composite score
        let compositeScore = calculateCompositeScore(
            goldAlignment: GoldAlignmentScore(
                semanticSimilarity: semanticSimilarity ?? 0.0,
                stringOverlap: stringOverlap ?? 0.0,
                styleToneScore: styleToneScore ?? 0.0
            ),
            redlinePenalty: redlinePenalty
        )
        
        // Create experiment score record
        let experimentScore = ExperimentScore(
            id: UUID(),
            experimentRunId: experimentRunId,
            situationId: UUID(uuidString: situation.id) ?? UUID(),
            guidanceId: UUID(uuidString: guidance.id) ?? UUID(),
            goldResponseId: goldResponse?.id,
            redlineResponseId: redlineResponse?.id,
            semanticSimilarity: semanticSimilarity,
            stringOverlap: stringOverlap,
            styleToneScore: styleToneScore,
            redlineSimilarity: redlineSimilarity,
            redlineKeywordHits: redlineKeywordHits,
            redlinePenalty: redlinePenalty,
            compositeScore: compositeScore,
            scoreWeights: getDefaultScoreWeights(),
            comparisonDetails: nil,
            createdAt: Date()
        )
        
        // Save to database
        try await saveExperimentScore(experimentScore)
        
        return experimentScore
    }
    
    // MARK: - Individual Scoring Methods
    
    private func calculateSemanticSimilarity(text1: String, text2: String) async throws -> Double {
        // This would use embeddings to calculate semantic similarity
        // For now, return a placeholder - should integrate with EdgeFunction embedding generation
        return 0.5
    }
    
    private func calculateRougeL(reference: String, candidate: String) -> Double {
        // Implement ROUGE-L (Longest Common Subsequence) scoring
        let refTokens = tokenize(reference)
        let candTokens = tokenize(candidate)
        
        let lcsLength = longestCommonSubsequence(refTokens, candTokens)
        let precision = Double(lcsLength) / Double(candTokens.count)
        let recall = Double(lcsLength) / Double(refTokens.count)
        
        if precision + recall == 0 {
            return 0.0
        }
        
        let fScore = (2.0 * precision * recall) / (precision + recall)
        return fScore
    }
    
    private func calculateStyleToneScore(guidance: String, goldResponse: String) async throws -> Double {
        // This would use LLM evaluation against style/tone criteria
        // For now, return a placeholder - should integrate with EdgeFunction
        return 0.7
    }
    
    // MARK: - Composite Scoring
    
    private func calculateCompositeScore(
        goldAlignment: GoldAlignmentScore,
        redlinePenalty: Double
    ) -> Double {
        let weights = ScoreWeights.default
        
        let goldScore = (goldAlignment.semanticSimilarity * weights.semanticWeight) +
                       (goldAlignment.stringOverlap * weights.stringOverlapWeight) +
                       (goldAlignment.styleToneScore * weights.styleToneWeight)
        
        let compositeScore = (goldScore * weights.goldWeight) - (redlinePenalty * weights.redlineWeight)
        
        // Clamp to reasonable range
        return max(0.0, min(1.0, compositeScore))
    }
    
    private func getDefaultScoreWeights() -> ScoreWeights {
        return ScoreWeights.default
    }
    
    // MARK: - Database Operations
    
    private func saveExperimentScore(_ score: ExperimentScore) async throws {
        try await supabaseManager.client
            .from("experiment_scores")
            .insert(score)
            .execute()
    }

    // Save with explanations (bullets/highlights) without regenRunId linkage
    func saveExperimentScoreWithExplanations(_ score: ExperimentScore, explanations: [String: Any]) async throws {
        struct InsertWithExplanations: Encodable {
            let id: UUID
            let experimentRunId: UUID
            let situationId: UUID
            let guidanceId: UUID
            let goldResponseId: UUID?
            let redlineResponseId: UUID?
            let semanticSimilarity: Double?
            let stringOverlap: Double?
            let styleToneScore: Double?
            let redlineSimilarity: Double?
            let redlineKeywordHits: Int?
            let redlinePenalty: Double?
            let compositeScore: Double
            let scoreWeights: ScoreWeights
            let comparisonDetails: ComparisonDetails?
            let createdAt: Date
            let explanationsJson: [String: Any]
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
                case explanationsJson = "explanations_json"
            }
        }
        let payload = InsertWithExplanations(
            id: score.id,
            experimentRunId: score.experimentRunId,
            situationId: score.situationId,
            guidanceId: score.guidanceId,
            goldResponseId: score.goldResponseId,
            redlineResponseId: score.redlineResponseId,
            semanticSimilarity: score.semanticSimilarity,
            stringOverlap: score.stringOverlap,
            styleToneScore: score.styleToneScore,
            redlineSimilarity: score.redlineSimilarity,
            redlineKeywordHits: score.redlineKeywordHits,
            redlinePenalty: score.redlinePenalty,
            compositeScore: score.compositeScore,
            scoreWeights: score.scoreWeights,
            comparisonDetails: score.comparisonDetails,
            createdAt: score.createdAt,
            explanationsJson: explanations
        )
        try await supabaseManager.client
            .from("experiment_scores")
            .insert(payload)
            .execute()
    }

    // Overload to save with regen_run_id linkage when available
    func saveExperimentScore(_ score: ExperimentScore, regenRunId: UUID?) async throws {
        if let regenRunId = regenRunId {
            struct InsertWithRun: Encodable {
                let id: UUID
                let experimentRunId: UUID
                let situationId: UUID
                let guidanceId: UUID
                let goldResponseId: UUID?
                let redlineResponseId: UUID?
                let semanticSimilarity: Double?
                let stringOverlap: Double?
                let styleToneScore: Double?
                let redlineSimilarity: Double?
                let redlineKeywordHits: Int?
                let redlinePenalty: Double?
                let compositeScore: Double
                let scoreWeights: ScoreWeights
                let comparisonDetails: ComparisonDetails?
                let createdAt: Date
                let explanationsJson: [String: Any]?
                let regenRunId: UUID
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
                    case explanationsJson = "explanations_json"
                    case createdAt = "created_at"
                    case regenRunId = "regen_run_id"
                }
            }
            let payload = InsertWithRun(
                id: score.id,
                experimentRunId: score.experimentRunId,
                situationId: score.situationId,
                guidanceId: score.guidanceId,
                goldResponseId: score.goldResponseId,
                redlineResponseId: score.redlineResponseId,
                semanticSimilarity: score.semanticSimilarity,
                stringOverlap: score.stringOverlap,
                styleToneScore: score.styleToneScore,
                redlineSimilarity: score.redlineSimilarity,
                redlineKeywordHits: score.redlineKeywordHits,
                redlinePenalty: score.redlinePenalty,
                compositeScore: score.compositeScore,
                scoreWeights: score.scoreWeights,
                comparisonDetails: score.comparisonDetails,
                createdAt: score.createdAt,
                explanationsJson: ["bullets": ["Clear steps", "Grounded in context"], "highlights": []],
                regenRunId: regenRunId
            )
            try await supabaseManager.client
                .from("experiment_scores")
                .insert(payload)
                .execute()
        } else {
            try await saveExperimentScore(score)
        }
    }

    // MARK: - Why-this-won explanations (heuristic)
    func createExplanations(guidanceText: String, contextSpans: [String] = []) -> [String: Any] {
        var bullets: [String] = []
        if guidanceText.lowercased().contains("step") || guidanceText.lowercased().contains("1.") {
            bullets.append("Actionable: clear step-by-step guidance")
        }
        if guidanceText.lowercased().contains("because") || guidanceText.lowercased().contains("context") {
            bullets.append("Grounded in context and reasoning")
        }
        if guidanceText.lowercased().contains("feel") || guidanceText.lowercased().contains("empath") {
            bullets.append("Empathetic tone and supportive framing")
        }
        if bullets.isEmpty { bullets = ["Clear, helpful, and safe"] }
        let highlights = Array(contextSpans.prefix(3))
        return ["bullets": bullets.prefix(3), "highlights": highlights]
    }
    
    func getExperimentScores(experimentRunId: UUID) async throws -> [ExperimentScore] {
        let response = try await supabaseManager.client
            .from("experiment_scores")
            .select()
            .eq("experiment_run_id", value: experimentRunId.uuidString)
            .order("composite_score", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([ExperimentScore].self, from: response.data)
    }
    
    func getTopScores(experimentRunId: UUID, limit: Int = 10) async throws -> [ExperimentScore] {
        let response = try await supabaseManager.client
            .from("experiment_scores")
            .select()
            .eq("experiment_run_id", value: experimentRunId.uuidString)
            .order("composite_score", ascending: false)
            .limit(limit)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([ExperimentScore].self, from: response.data)
    }
    
    // MARK: - Analytics
    
    func getScoreStatistics(experimentRunId: UUID) async throws -> ScoreStatistics {
        let scores = try await getExperimentScores(experimentRunId: experimentRunId)
        
        let compositeScores = scores.map { $0.compositeScore }
        
        return ScoreStatistics(
            totalSituations: scores.count,
            meanScore: compositeScores.isEmpty ? 0.0 : compositeScores.reduce(0, +) / Double(compositeScores.count),
            medianScore: median(compositeScores),
            p90Score: percentile(compositeScores, 90),
            bestScore: compositeScores.max() ?? 0.0,
            worstScore: compositeScores.min() ?? 0.0
        )
    }
    
    // MARK: - Utility Methods
    
    private func tokenize(_ text: String) -> [String] {
        return text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
    }
    
    private func longestCommonSubsequence(_ seq1: [String], _ seq2: [String]) -> Int {
        let m = seq1.count
        let n = seq2.count
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 1...m {
            for j in 1...n {
                if seq1[i-1] == seq2[j-1] {
                    dp[i][j] = dp[i-1][j-1] + 1
                } else {
                    dp[i][j] = max(dp[i-1][j], dp[i][j-1])
                }
            }
        }
        
        return dp[m][n]
    }
    
    private func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0.0 }
        let sorted = values.sorted()
        let count = sorted.count
        
        if count % 2 == 0 {
            return (sorted[count/2 - 1] + sorted[count/2]) / 2.0
        } else {
            return sorted[count/2]
        }
    }
    
    private func percentile(_ values: [Double], _ p: Int) -> Double {
        guard !values.isEmpty else { return 0.0 }
        let sorted = values.sorted()
        let index = Int(Double(sorted.count - 1) * Double(p) / 100.0)
        return sorted[min(index, sorted.count - 1)]
    }
}

// MARK: - Supporting Data Structures

struct GoldAlignmentScore {
    let semanticSimilarity: Double
    let stringOverlap: Double
    let styleToneScore: Double
}

struct ScoreStatistics {
    let totalSituations: Int
    let meanScore: Double
    let medianScore: Double
    let p90Score: Double
    let bestScore: Double
    let worstScore: Double
}

// MARK: - Error Types

enum ScoringError: LocalizedError {
    case missingGoldResponse
    case invalidScoreCalculation(String)
    case embeddingGenerationFailed
    case styleEvaluationFailed
    
    var errorDescription: String? {
        switch self {
        case .missingGoldResponse:
            return "Gold response required for scoring"
        case .invalidScoreCalculation(let message):
            return "Invalid score calculation: \(message)"
        case .embeddingGenerationFailed:
            return "Failed to generate embeddings for semantic similarity"
        case .styleEvaluationFailed:
            return "Failed to evaluate style and tone"
        }
    }
}
