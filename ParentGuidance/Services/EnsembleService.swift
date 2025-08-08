import Foundation
import Supabase

@MainActor
final class EnsembleService {
    static let shared = EnsembleService()
    private init() {}

    enum Mode { case bestOfN, sectionCompose }

    func chooseBest(of candidates: [(guidanceId: String, composite: Double)]) -> (String, [String: Any])? {
        guard let best = candidates.max(by: { $0.composite < $1.composite }) else { return nil }
        return (best.guidanceId, ["reason": "max composite"]) 
    }

    func persistEnsemble(
        experimentRunId: UUID,
        mode: Mode,
        components: [(guidanceId: String, composite: Double)],
        chosenGuidanceId: String,
        judgeSummary: [String: Any]
    ) async throws {
        struct Insert: Encodable {
            let experimentRunId: String
            let mode: String
            let componentsJson: [String: Any]
            let judgeSummaryJson: [String: Any]
            let chosen: Bool
            enum CodingKeys: String, CodingKey {
                case experimentRunId = "experiment_run_id"
                case mode
                case componentsJson = "components_json"
                case judgeSummaryJson = "judge_summary_json"
                case chosen
            }
        }
        let payload = Insert(
            experimentRunId: experimentRunId.uuidString,
            mode: (mode == .bestOfN ? "best_of_n" : "section_compose"),
            componentsJson: ["candidates": components.map { ["guidance_id": $0.guidanceId, "composite": $0.composite] }, "chosen_guidance_id": chosenGuidanceId],
            judgeSummaryJson: judgeSummary,
            chosen: true
        )
        try await SupabaseManager.shared.client
            .from("ensembles")
            .insert(payload)
            .execute()
    }
}


