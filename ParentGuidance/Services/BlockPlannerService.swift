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
}


