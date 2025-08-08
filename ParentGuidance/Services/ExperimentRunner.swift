import Foundation
import Supabase

@MainActor
class ExperimentRunner: ObservableObject {
    static let shared = ExperimentRunner()
    @Published var activeExperiments: [ExperimentRun] = []
    @Published var isRunning = false
    @Published var currentExperiment: ExperimentRun?
    @Published var logs: [String] = []
    
    private let supabaseManager = SupabaseManager.shared
    private let guidanceService = GuidanceGenerationService.shared
    private let scoringService = ScoringService.shared
    private let goldResponseService = GoldResponseService.shared
    private let planner = BlockPlannerService.shared
    private let ensemble = EnsembleService.shared
    
    private var processingTask: Task<Void, Never>?
    
    // MARK: - Experiment Management
    
    func createExperiment(
        familyId: UUID,
        name: String,
        description: String? = nil,
        config: ExperimentConfig,
        runType: ExperimentRunType = .manual,
        dateRange: DateRange? = nil,
        situationFilter: SituationFilter? = nil
    ) async throws -> ExperimentRun {
        
        let experiment = ExperimentRun(
            id: UUID(),
            familyId: familyId,
            name: name,
            description: description,
            config: config,
            status: .queued,
            runType: runType,
            dateRange: dateRange,
            situationFilter: situationFilter,
            progress: ExperimentProgress(
                totalSituations: 0,
                processedSituations: 0,
                currentSituationId: nil,
                situationsWithGold: 0,
                situationsWithRedline: 0,
                averageCompositeScore: nil
            ),
            startedAt: nil,
            completedAt: nil,
            errorMessage: nil,
            createdBy: supabaseManager.getCurrentUserId(),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await supabaseManager.client
            .from("experiment_runs")
            .insert(experiment)
            .execute()
        
        return experiment
    }
    
    func startExperiment(_ experimentId: UUID) async throws {
        // Update status to running
        try await supabaseManager.client
            .from("experiment_runs")
            .update([
                "status": ExperimentStatus.running.rawValue,
                "started_at": Date().ISO8601Format()
            ])
            .eq("id", value: experimentId.uuidString)
            .execute()
        
        // Load experiment details
        let response = try await supabaseManager.client
            .from("experiment_runs")
            .select()
            .eq("id", value: experimentId.uuidString)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        currentExperiment = try decoder.decode(ExperimentRun.self, from: response.data)
        
        isRunning = true
        
        // Start processing
        processingTask = Task {
            await processExperiment()
        }
    }
    
    func pauseExperiment(_ experimentId: UUID) async throws {
        processingTask?.cancel()
        
        try await supabaseManager.client
            .from("experiment_runs")
            .update(["status": ExperimentStatus.paused.rawValue])
            .eq("id", value: experimentId.uuidString)
            .execute()
        
        isRunning = false
        log("Experiment paused")
    }
    
    func resumeExperiment(_ experimentId: UUID) async throws {
        try await startExperiment(experimentId)
    }
    
    // MARK: - Experiment Processing
    
    private func processExperiment() async {
        guard let experiment = currentExperiment else { return }
        
        do {
            log("Starting experiment: \(experiment.name)")
            
            // Fetch situations for the experiment
            let situations = try await fetchSituationsForExperiment(experiment)
            
            log("Found \(situations.count) situations to process")
            
            // Update progress
            var progress = experiment.progress
            progress.totalSituations = situations.count
            try await updateExperimentProgress(experimentId: experiment.id, progress: progress)
            
            // Process each situation
            for (index, situation) in situations.enumerated() {
                if Task.isCancelled { break }
                
                progress.currentSituationId = UUID(uuidString: situation.id)
                try await updateExperimentProgress(experimentId: experiment.id, progress: progress)
                
                log("Processing situation \(index + 1)/\(situations.count)")
                
                do {
                    // Optional planner step (scaffold): generate candidate plans for target block
                    let plans = planner.generatePlans(targetBlock: "context_extraction", count: 3)
                    _ = try? await planner.persistPlans(plans)
                    var candidates: [(guidance: Guidance, composite: Double)] = []
                    let variants = max(1, plans.count)
                    for v in 0..<variants {
                        let resolvedPolicy = await PolicySelector.shared.resolvePolicy(
                            familyId: UUID(uuidString: situation.familyId),
                            config: nil,
                            issueType: nil,
                            ageBand: nil
                        )
                        let guidanceResponse = try await generateExperimentalGuidance(
                            situation: situation,
                            config: experiment.config,
                            experimentId: experiment.id,
                            resolvedPolicy: resolvedPolicy
                        )
                        // Score
                        var score = try await scoringService.scoreGuidance(
                            guidanceText: guidanceResponse.content,
                            goldResponse: try await goldResponseService.getGoldResponse(for: UUID(uuidString: situation.id) ?? UUID()),
                            redlineResponse: try await goldResponseService.getRedlineResponse(for: UUID(uuidString: situation.id) ?? UUID())
                        )
                        // Update IDs and persist
                        score.experimentRunId = experiment.id
                        score.situationId = UUID(uuidString: situation.id) ?? UUID()
                        score.guidanceId = UUID(uuidString: guidanceResponse.id) ?? UUID()
                        let explanations = scoringService.createExplanations(guidanceText: guidanceResponse.content)
                        try await scoringService.saveExperimentScoreWithExplanations(score, explanations: explanations)
                        candidates.append((guidanceResponse, score.compositeScore))
                    }
                    // Choose best-of-N and persist ensemble
                    let mapped = candidates.map { (guidanceId: $0.guidance.id, composite: $0.composite) }
                    if let (chosenId, judgeSummary) = ensemble.chooseBest(of: mapped) {
                        let ensembleId = try? await ensemble.persistEnsemble(
                            experimentRunId: experiment.id,
                            mode: .bestOfN,
                            components: mapped,
                            chosenGuidanceId: chosenId,
                            judgeSummary: judgeSummary
                        )
                    }

                    // Attempt section-wise compose of candidates and re-judge (safety gate naive)
                    if let composed = await ensemble.sectionCompose(candidates: candidates) {
                        var compScore = try await scoringService.scoreGuidance(
                            guidanceText: composed.content,
                            goldResponse: try await goldResponseService.getGoldResponse(for: UUID(uuidString: situation.id) ?? UUID()),
                            redlineResponse: try await goldResponseService.getRedlineResponse(for: UUID(uuidString: situation.id) ?? UUID())
                        )
                        compScore.experimentRunId = experiment.id
                        compScore.situationId = UUID(uuidString: situation.id) ?? UUID()
                        compScore.guidanceId = UUID(uuidString: composed.id) ?? UUID()
                        let explanations = scoringService.createExplanations(guidanceText: composed.content)
                        try await scoringService.saveExperimentScoreWithExplanations(compScore, explanations: explanations)
                        // If composed improves composite and redline not worse than max candidate penalty, persist as ensemble too
                        let baseline = candidates.map { $0.composite }.max() ?? 0
                        if compScore.compositeScore >= baseline {
                            let ensembleId = try? await ensemble.persistEnsemble(
                                experimentRunId: experiment.id,
                                mode: .sectionCompose,
                                components: mapped,
                                chosenGuidanceId: composed.id,
                                judgeSummary: ["reason": "section-compose uplift"]
                            )
                        }
                    }

                    // LLM Synthesis attempt
                    if let synthesized = try? await ensemble.llmSynthesis(
                        situationId: situation.id,
                        familyId: situation.familyId,
                        candidates: candidates
                    ) {
                        var synScore = try await scoringService.scoreGuidance(
                            guidanceText: synthesized.content,
                            goldResponse: try await goldResponseService.getGoldResponse(for: UUID(uuidString: situation.id) ?? UUID()),
                            redlineResponse: try await goldResponseService.getRedlineResponse(for: UUID(uuidString: situation.id) ?? UUID())
                        )
                        synScore.experimentRunId = experiment.id
                        synScore.situationId = UUID(uuidString: situation.id) ?? UUID()
                        synScore.guidanceId = UUID(uuidString: synthesized.id) ?? UUID()
                        let explanations = scoringService.createExplanations(guidanceText: synthesized.content)
                        try await scoringService.saveExperimentScoreWithExplanations(synScore, explanations: explanations)
                    }
                    
                    progress.processedSituations += 1
                    try await updateExperimentProgress(experimentId: experiment.id, progress: progress)
                    
                    // Rate limiting
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
                    
                } catch {
                    log("Error processing situation \(situation.id): \(error.localizedDescription)")
                    // Continue with next situation
                }
            }
            
            // Mark as completed
            try await completeExperiment(experiment.id)
            
        } catch {
            log("Fatal error in experiment: \(error.localizedDescription)")
            try? await failExperiment(experiment.id, error: error.localizedDescription)
        }
    }
    
    private func fetchSituationsForExperiment(_ experiment: ExperimentRun) async throws -> [Situation] {
        var query = supabaseManager.client
            .from("situations")
            .select()
            .eq("family_id", value: experiment.familyId.uuidString)
            .order("created_at", ascending: true)
        if let range = experiment.dateRange {
            let formatter = ISO8601DateFormatter()
            query = query.gte("created_at", value: formatter.string(from: range.start))
                .lte("created_at", value: formatter.string(from: range.end))
        }
        if let filter = experiment.situationFilter {
            if let cats = filter.categories, !cats.isEmpty {
                query = query.in("category", value: cats)
            }
            if let hasIncident = filter.hasIncident {
                query = query.eq("is_incident", value: hasIncident)
            }
            if let search = filter.textSearch, !search.isEmpty {
                query = query.ilike("description", value: "%\(search)%")
            }
        }
        let response = try await query.execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Situation].self, from: response.data)
    }
    
    private func generateExperimentalGuidance(
        situation: Situation,
        config: ExperimentConfig,
        experimentId: UUID,
        resolvedPolicy: ResolvedPolicy
    ) async throws -> Guidance {
        
        // Get API key
        guard let apiKey = UserDefaults.standard.string(forKey: "openAIApiKey") else {
            throw ExperimentError.noApiKey
        }
        
        // Generate guidance
        let (guidanceResponse, rawContent) = try await guidanceService.generateGuidance(
            situation: situation.description,
            childContext: nil,
            keyInsights: nil,
            copingStrategies: nil,
            apiKey: apiKey,
            activeFramework: nil,
            situationType: .imJustWondering,
            useStreaming: false,
            resolvedPolicy: resolvedPolicy
        )
        
        // Save the guidance with experiment ID
        let guidanceId = UUID().uuidString
        let guidance = Guidance(
            id: guidanceId,
            situationId: situation.id,
            content: rawContent,
            category: nil,
            overallRecommendation: guidanceResponse.title
        )
        
        struct GuidanceInsert: Encodable {
            let id: String
            let situationId: String
            let content: String
            let category: String?
            let overallRecommendation: String?
            let experimentRunId: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case situationId = "situation_id"
                case content
                case category
                case overallRecommendation = "overall_recommendation"
                case experimentRunId = "experiment_run_id"
            }
        }
        
        let guidanceInsert = GuidanceInsert(
            id: guidance.id,
            situationId: guidance.situationId,
            content: guidance.content,
            category: guidance.category,
            overallRecommendation: guidance.overallRecommendation,
            experimentRunId: experimentId.uuidString
        )
        
        try await supabaseManager.client
            .from("guidance")
            .insert(guidanceInsert)
            .execute()
        
        return guidance
    }
    
    private func scoreGuidance(
        situation: Situation,
        guidance: Guidance,
        experimentId: UUID
    ) async throws {
        
        // Get gold and redline responses
        let goldResponse = try await goldResponseService.getGoldResponse(for: UUID(uuidString: situation.id) ?? UUID())
        let redlineResponse = try await goldResponseService.getRedlineResponse(for: UUID(uuidString: situation.id) ?? UUID())
        
        // Skip scoring if no benchmarks exist
        guard goldResponse != nil || redlineResponse != nil else {
            log("No benchmarks found for situation \(situation.id), skipping scoring")
            return
        }
        
        // Score the guidance
        var score = try await scoringService.scoreGuidance(
            guidanceText: guidance.content,
            goldResponse: goldResponse,
            redlineResponse: redlineResponse
        )
        
        // Update with correct IDs
        score.experimentRunId = experimentId
        score.situationId = UUID(uuidString: situation.id) ?? UUID()
        score.guidanceId = UUID(uuidString: guidance.id) ?? UUID()
        
        // Save the score
        try await supabaseManager.client
            .from("experiment_scores")
            .insert(score)
            .execute()
        
        log("Scored guidance: composite score = \(String(format: "%.3f", score.compositeScore))")
    }
    
    // MARK: - Progress Management
    
    private func updateExperimentProgress(experimentId: UUID, progress: ExperimentProgress) async throws {
        let encoder = JSONEncoder()
        let progressData = try encoder.encode(progress)
        let progressJSON = try JSONSerialization.jsonObject(with: progressData) as? [String: Any] ?? [:]
        
        struct ProgressUpdate: Encodable {
            let progress: [String: Any]
            
            enum CodingKeys: String, CodingKey {
                case progress
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                // This is a simplified approach - in production you'd want to properly encode the progress
                let progressData = try JSONSerialization.data(withJSONObject: progress)
                let progressString = String(data: progressData, encoding: .utf8) ?? "{}"
                try container.encode(progressString, forKey: .progress)
            }
        }
        
        let updateData = ProgressUpdate(progress: progressJSON)
        try await supabaseManager.client
            .from("experiment_runs")
            .update(updateData)
            .eq("id", value: experimentId.uuidString)
            .execute()
    }
    
    private func completeExperiment(_ experimentId: UUID) async throws {
        try await supabaseManager.client
            .from("experiment_runs")
            .update([
                "status": ExperimentStatus.completed.rawValue,
                "completed_at": Date().ISO8601Format()
            ])
            .eq("id", value: experimentId.uuidString)
            .execute()
        
        isRunning = false
        log("Experiment completed successfully!")
    }
    
    private func failExperiment(_ experimentId: UUID, error: String) async throws {
        try await supabaseManager.client
            .from("experiment_runs")
            .update([
                "status": ExperimentStatus.failed.rawValue,
                "error_message": error,
                "completed_at": Date().ISO8601Format()
            ])
            .eq("id", value: experimentId.uuidString)
            .execute()
        
        isRunning = false
    }
    
    // MARK: - Leaderboard Data
    
    func getExperimentLeaderboard(familyId: UUID) async throws -> [ExperimentLeaderboardEntry] {
        let response = try await supabaseManager.client
            .from("experiment_runs")
            .select("*, experiment_scores(composite_score)")
            .eq("family_id", value: familyId.uuidString)
            .eq("status", value: ExperimentStatus.completed.rawValue)
            .order("created_at", ascending: false)
            .execute()
        
        struct Row: Decodable {
            let id: String
            let name: String
            let config: ExperimentConfig
            let completed_at: String?
            let experiment_scores: [ScoreRow]?
        }
        struct ScoreRow: Decodable { let composite_score: Double }
        let decoder = JSONDecoder()
        let rows = try decoder.decode([Row].self, from: response.data)
        var entries: [ExperimentLeaderboardEntry] = rows.map { row in
            let avg = (row.experiment_scores?.map { $0.composite_score } ?? []).average()
            let completedAt: Date = ISO8601DateFormatter().date(from: row.completed_at ?? "") ?? Date()
            return ExperimentLeaderboardEntry(
                experimentId: UUID(uuidString: row.id) ?? UUID(),
                name: row.name,
                config: row.config,
                averageScore: avg,
                situationsProcessed: row.experiment_scores?.count ?? 0,
                completedAt: completedAt
            )
        }
        entries.sort { $0.averageScore > $1.averageScore }
        return entries
    }
    
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"
        logs.append(logMessage)
        
        // Keep only last 100 logs
        if logs.count > 100 {
            logs.removeFirst()
        }
    }
}

// MARK: - Supporting Types

struct ExperimentLeaderboardEntry {
    let experimentId: UUID
    let name: String
    let config: ExperimentConfig
    let averageScore: Double
    let situationsProcessed: Int
    let completedAt: Date
}

// MARK: - Error Types

enum ExperimentError: LocalizedError {
    case noApiKey
    case invalidConfiguration
    case processingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noApiKey:
            return "No API key found"
        case .invalidConfiguration:
            return "Invalid experiment configuration"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        }
    }
}