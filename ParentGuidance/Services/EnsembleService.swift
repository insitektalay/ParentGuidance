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
    ) async throws -> UUID {
        struct Insert: Encodable {
            let id: String
            let experimentRunId: String
            let mode: String
            let componentsJson: [String: Any]
            let judgeSummaryJson: [String: Any]
            let chosen: Bool
            enum CodingKeys: String, CodingKey {
                case id
                case experimentRunId = "experiment_run_id"
                case mode
                case componentsJson = "components_json"
                case judgeSummaryJson = "judge_summary_json"
                case chosen
            }
        }
        let ensembleId = UUID()
        let payload = Insert(
            id: ensembleId.uuidString,
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
        return ensembleId
    }

    // Section-wise compose: pick best section per candidate (stubbed behavior)
    func sectionCompose(
        candidates: [(guidance: Guidance, composite: Double)]
    ) -> Guidance? {
        // TODO: Implement proper section-level merge
        return candidates.max(by: { $0.composite < $1.composite })?.guidance
    }

    // LLM Synthesis stub: merge top-2 guidance texts
    func llmSynthesis(
        situationId: String,
        familyId: String?,
        candidates: [(guidance: Guidance, composite: Double)]
    ) async throws -> Guidance? {
        guard candidates.count >= 2 else { return nil }
        let top2 = candidates.sorted { $0.composite > $1.composite }.prefix(2)
        let mergedContent = top2.map { $0.guidance.content }.joined(separator: "\n\n—\n\n")
        // Save synthesized guidance so it can be scored
        let savedId = try await ConversationService.shared.saveGuidance(
            situationId: situationId,
            content: mergedContent,
            category: nil,
            overallRecommendation: nil,
            regenRunId: nil,
            experimentRunId: nil
        )
        return Guidance(id: savedId, situationId: situationId, content: mergedContent, category: nil)
    }
}


