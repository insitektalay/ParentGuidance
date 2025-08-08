import Foundation

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

    /// Persist evaluated plan results with judge summaries and win/fail flags.
    func persistPlans(_ plans: [BlockPlan]) async throws {
        let enc = JSONEncoder()
        for plan in plans {
            var dict: [String: Any] = [
                "id": plan.id.uuidString,
                "ablation_run_id": plan.ablationRunId.uuidString,
                "plan_text": plan.planText,
                "params_json": try? JSONSerialization.jsonObject(with: try enc.encode(plan.paramsJson)),
                "judge_summary_json": try? JSONSerialization.jsonObject(with: try enc.encode(plan.judgeSummaryJson ?? [:])),
                "picked": plan.picked,
                "created_at": ISO8601DateFormatter().string(from: plan.createdAt)
            ]
            try await SupabaseManager.shared.client
                .from("block_plans")
                .insert(dict)
                .execute()
        }
    }
}


