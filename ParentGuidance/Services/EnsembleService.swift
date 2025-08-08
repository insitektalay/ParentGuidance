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
        guard !candidates.isEmpty else { return nil }
        // Parse sections using DynamicGuidanceParser; if parsing fails, fall back to full text
        struct NamedSection { let name: String; let content: String }
        var candidateSections: [[NamedSection]] = []
        for c in candidates {
            if let parsed = DynamicGuidanceParser.shared.parseWithFallback(c.guidance.content) as? GuidanceResponseProtocol {
                let sections = parsed.displaySections.map { NamedSection(name: $0.title, content: $0.content) }
                candidateSections.append(sections)
            } else {
                candidateSections.append([NamedSection(name: "Content", content: c.guidance.content)])
            }
        }
        // Collect by section name and pick best by candidate composite
        var merged: [NamedSection] = []
        let sectionNames = Set(candidateSections.flatMap { $0.map { $0.name } })
        for name in sectionNames {
            var best: (idx: Int, content: String, composite: Double)?
            for (i, sections) in candidateSections.enumerated() {
                if let sec = sections.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }), candidates.indices.contains(i) {
                    let comp = candidates[i].composite
                    if best == nil || comp > (best?.composite ?? 0) {
                        best = (i, sec.content, comp)
                    }
                }
            }
            if let b = best { merged.append(NamedSection(name: name, content: b.content)) }
        }
        // Compose back into text
        var composed = ""
        for s in merged.sorted(by: { $0.name < $1.name }) {
            composed += "[\(s.name.uppercased())]\n\(s.content)\n\n"
        }
        // Save composed guidance
        guard let first = candidates.first?.guidance else { return nil }
        if let savedId = try? await ConversationService.shared.saveGuidance(
            situationId: first.situationId,
            content: composed,
            category: nil,
            overallRecommendation: nil,
            regenRunId: nil,
            experimentRunId: nil
        ) {
            return Guidance(id: savedId, situationId: first.situationId, content: composed, category: nil)
        }
        return nil
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


