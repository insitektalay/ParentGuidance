import Foundation
import Supabase

@MainActor
final class BlockPlannerService {
    static let shared = BlockPlannerService()
    private init() {}

    /// Generate N candidate plans for a target block with simple constraints.
    func generatePlans(targetBlock: String, count: Int = 3) async -> [BlockPlan] {
        let now = Date()
        return (0..<count).map { idx in
            BlockPlan(
                id: UUID(),
                ablationRunId: UUID(),
                planText: "Auto plan #\(idx+1) for \(targetBlock)",
                paramsJson: ["k": AnyCodable(3 + idx)],
                judgeSummaryJson: nil,
                picked: idx == 0,
                createdAt: now
            )
        }
    }

    // LLM-driven proposal with guardrails
    func proposePlansViaLLM(targetBlock: String, maxCandidates: Int = 5, maxLatencyMs: Int = 8000) async -> [BlockPlan] {
        let start = Date()
        var proposed: [BlockPlan] = []
        defer {
            // Guardrail: latency
            let elapsed = Int(Date().timeIntervalSince(start) * 1000)
            if elapsed > maxLatencyMs { proposed = Array(proposed.prefix(3)) }
        }
        // Use Direct API to ask for JSON of plan params (fallback path)
        guard let apiKey = UserDefaults.standard.string(forKey: "openAIApiKey") else { return [] }
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let prompt = "You are a planner for \(targetBlock). Propose between 3 and \(maxCandidates) JSON objects with constrained parameters for safety, latency, and token budget. Keys may include k, recency_days, min_sim, issue_filter. Return ONLY a JSON array of objects."
        let body: [String: Any] = ["input": prompt, "model": "gpt-4o-mini"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let output = (json["output"] as? [[String: Any]])?.first,
               let contentArr = output["content"] as? [[String: Any]],
               let content = contentArr.first?["text"] as? String,
               let plansArrData = content.data(using: .utf8),
               let arr = try? JSONSerialization.jsonObject(with: plansArrData) as? [[String: Any]] {
                let now = Date()
                for (idx, item) in arr.enumerated() {
                    if idx >= maxCandidates { break }
                    proposed.append(
                        BlockPlan(
                            id: UUID(),
                            ablationRunId: UUID(),
                            planText: "LLM plan #\(idx+1) for \(targetBlock)",
                            paramsJson: item.mapValues { AnyCodable($0) },
                            judgeSummaryJson: nil,
                            picked: false,
                            createdAt: now
                        )
                    )
                }
            }
        } catch {
            return []
        }
        return proposed
    }

    /// Persist evaluated plan results with judge summaries and win/fail flags.
    func persistPlans(_ plans: [BlockPlan]) async throws {
        struct InsertRow: Encodable {
            let id: String
            let ablationRunId: String
            let planText: String
            let paramsJson: String
            let judgeSummaryJson: String
            let picked: Bool
            let createdAt: String
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
        let enc = JSONEncoder()
        var rows: [InsertRow] = []
        for plan in plans {
            let paramsData = try enc.encode(plan.paramsJson)
            let judgeData = try enc.encode(plan.judgeSummaryJson ?? [:])
            rows.append(
                InsertRow(
                    id: plan.id.uuidString,
                    ablationRunId: plan.ablationRunId.uuidString,
                    planText: plan.planText,
                    paramsJson: String(data: paramsData, encoding: .utf8) ?? "{}",
                    judgeSummaryJson: String(data: judgeData, encoding: .utf8) ?? "{}",
                    picked: plan.picked,
                    createdAt: ISO8601DateFormatter().string(from: plan.createdAt)
                )
            )
        }
        if !rows.isEmpty {
            try await SupabaseManager.shared.client
                .from("block_plans")
                .insert(rows)
                .execute()
        }
    }
}


