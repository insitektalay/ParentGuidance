import Foundation

// MARK: - Policy Selector

@MainActor
final class PolicySelector {
    static let shared = PolicySelector()
    private init() {}

    /// Resolve a ResolvedPolicy for a given run. For now, bridges existing UserDefaults flags → policy fields.
    func resolvePolicy(
        familyId: UUID?,
        config: RegenConfig?,
        issueType: String? = nil,
        ageBand: String? = nil
    ) -> ResolvedPolicy {
        // Model provider from config or fallback to stored selection
        let provider = config?.modelProvider
            ?? UserDefaults.standard.string(forKey: "selectedModelProvider")
            ?? "openai/gpt-4o"

        // Guidance knobs via existing settings
        let guidanceMode = UserDefaults.standard.string(forKey: "guidanceMode") ?? "fixed"
        let guidanceStyle = UserDefaults.standard.string(forKey: "guidanceStyle") ?? "Warm Practical"

        // Context extraction toggle via prior flag
        let contextEnabled = UserDefaults.standard.bool(forKey: "aiProcessingContextExtraction")
        // Relevant insights toggle via prior flag
        let relevantEnabled = UserDefaults.standard.bool(forKey: "aiProcessingRelevantInsights")

        // Assemble policy
        // Try cohort-pinned overrides from registry
        let cohortOverrides = try? awaitCohortOverrides(issueType: issueType, ageBand: ageBand)

        let blocks = PromptBlocks(
            similarCase: nil,
            actionTemplate: nil,
            contextExtraction: ContextExtractionParams(
                enabled: cohortOverrides?.contextEnabled ?? contextEnabled,
                provider: cohortOverrides?.contextProvider ?? "edge",
                batchSize: cohortOverrides?.batchSize ?? 10,
                delayMs: cohortOverrides?.delayMs ?? 1000,
                similarityThreshold: cohortOverrides?.similarityThreshold ?? config?.similarityThreshold,
                language: cohortOverrides?.language ?? "auto"
            ),
            relevantInsights: ToggleBlock(enabled: relevantEnabled),
            analysis: AnalysisParams(enabled: true, provider: "edge", promptVersion: "v1"),
            translation: TranslationParams(enabled: false, targetLanguage: nil, smartOnDemand: true)
        )

        return ResolvedPolicy(
            modelProvider: provider,
            temperature: 0.3,
            topP: 0.9,
            seed: config?.determinismSeed?.doubleValue,
            guidance: GuidanceParams(
                useFunctionCalling: true,
                structureMode: "fixed",
                guidanceStyle: guidanceStyle,
                situationType: nil
            ),
            promptBlocks: blocks
        )
    }

    private struct CohortOverrides {
        let contextEnabled: Bool
        let contextProvider: String
        let batchSize: Int
        let delayMs: Int
        let similarityThreshold: Double?
        let language: String?
    }

    private func awaitCohortOverrides(issueType: String?, ageBand: String?) async throws -> CohortOverrides? {
        guard let issue = issueType, let age = ageBand else { return nil }
        // For v1, we simply check if any cohort pin exists and return hardcoded overrides.
        // In v2, map pin -> concrete params_json.
        let client = SupabaseManager.shared.client
        let pins = try await client
            .from("block_cohort_pins")
            .select()
            .eq("issue_type", value: issue)
            .eq("age_band", value: age)
            .eq("enabled", value: true)
            .limit(1)
            .execute()
        if pins.data.isEmpty { return nil }
        return CohortOverrides(
            contextEnabled: true,
            contextProvider: "edge",
            batchSize: 10,
            delayMs: 1000,
            similarityThreshold: 0.8,
            language: "auto"
        )
    }
}

private extension Int {
    var doubleValue: Double { Double(self) }
}


