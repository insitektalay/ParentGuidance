import Foundation

// MARK: - Policy Selector

@MainActor
final class PolicySelector {
    static let shared = PolicySelector()
    private init() {}

    /// Resolve a ResolvedPolicy for a given run. For now, bridges existing UserDefaults flags → policy fields.
    func resolvePolicy(familyId: UUID?, config: RegenConfig?) -> ResolvedPolicy {
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
        let blocks = PromptBlocks(
            similarCase: nil,
            actionTemplate: nil,
            contextExtraction: ContextExtractionParams(
                enabled: contextEnabled,
                provider: "edge",
                batchSize: 10,
                delayMs: 1000,
                similarityThreshold: config?.similarityThreshold,
                language: "auto"
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
            promptBlocks: blocks
        )
    }
}

private extension Int {
    var doubleValue: Double { Double(self) }
}


