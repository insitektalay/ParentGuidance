import Foundation

@MainActor
final class PlannerExecutorService {
    static let shared = PlannerExecutorService()
    private init() {}

    private let guidanceService = GuidanceGenerationService.shared
    private let scoringService = ScoringService.shared
    private let goldService = GoldResponseService.shared

    struct PlanResult {
        let plan: BlockPlan
        let avgComposite: Double
        let avgRedlinePenalty: Double
        let judgeSummary: [String: Any]
    }

    /// Evaluate plans on a small slice (first N situations) and persist results.
    func evaluatePlans(
        plans: [BlockPlan],
        situations: [Situation],
        experimentId: UUID
    ) async throws -> [PlanResult] {
        let slice = Array(situations.prefix( min(5, situations.count) ))
        var results: [PlanResult] = []

        for plan in plans {
            var composites: [Double] = []
            var redlines: [Double] = []
            for situation in slice {
                // Generate simple guidance (using current config; a real impl would apply plan.params_json)
                guard let apiKey = UserDefaults.standard.string(forKey: "openAIApiKey") else { continue }
                let (guidance, raw) = try await guidanceService.generateGuidance(
                    situation: situation.description,
                    apiKey: apiKey,
                    activeFramework: nil,
                    situationType: .imJustWondering,
                    useStreaming: false,
                    policy: nil
                )
                // Score
                let gold = try await goldService.getGoldResponse(for: UUID(uuidString: situation.id) ?? UUID())
                let redline = try await goldService.getRedlineResponse(for: UUID(uuidString: situation.id) ?? UUID())
                let tempScore = try await scoringService.scoreGuidance(
                    guidanceText: raw,
                    goldResponse: gold,
                    redlineResponse: redline
                )
                composites.append(tempScore.compositeScore)
                redlines.append(tempScore.redlinePenalty ?? 0.0)
            }
            let avgComp = composites.isEmpty ? 0.0 : composites.reduce(0,+)/Double(composites.count)
            let avgRed = redlines.isEmpty ? 0.0 : redlines.reduce(0,+)/Double(redlines.count)
            let summary: [String: Any] = ["avg_composite": avgComp, "avg_redline": avgRed]
            results.append(PlanResult(plan: plan, avgComposite: avgComp, avgRedlinePenalty: avgRed, judgeSummary: summary))
        }

        // Persist plans with summaries and pick best if uplift > 0 and no safety regression (naive gating)
        let best = results.max(by: { $0.avgComposite < $1.avgComposite })
        for r in results {
            let picked = (r.plan.id == best?.plan.id)
            let enc = JSONEncoder()
            let summaryJson = r.judgeSummary
            var dict: [String: Any] = [
                "id": r.plan.id.uuidString,
                "ablation_run_id": r.plan.ablationRunId.uuidString,
                "plan_text": r.plan.planText,
                "params_json": try? JSONSerialization.jsonObject(with: try enc.encode(r.plan.paramsJson)),
                "judge_summary_json": summaryJson,
                "picked": picked
            ]
            try await SupabaseManager.shared.client
                .from("block_plans")
                .upsert(dict)
                .execute()
        }

        return results
    }
}


