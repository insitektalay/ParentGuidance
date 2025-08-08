import Foundation
import Supabase

@MainActor
final class AblationService: ObservableObject {
    static let shared = AblationService()
    private init() {}

    private let supabase = SupabaseManager.shared.client
    private let orchestrator = RegenOrchestrator()

    struct AblationConfig {
        let targetBlock: String
        let paramKey: String
        let controlValue: String
        let testValue: String
        let sliceDef: [String: String]?
    }

    /// Run a simple ablation: control vs test on the same slice. Inserts an ablation_runs row.
    func runAblation(
        familyId: UUID,
        experimentRunId: UUID,
        regenConfig: RegenConfig,
        ablation: AblationConfig
    ) async throws -> UUID {
        // Insert ablation_runs row
        let id = UUID()
        struct Insert: Encodable {
            let id: UUID
            let experimentRunId: UUID
            let blockName: String
            let paramKey: String
            let controlValue: String
            let testValue: String
            let sliceDef: [String: String]?
            enum CodingKeys: String, CodingKey {
                case id
                case experimentRunId = "experiment_run_id"
                case blockName = "block_name"
                case paramKey = "param_key"
                case controlValue = "control_value"
                case testValue = "test_value"
                case sliceDef = "slice_def"
            }
        }
        try await supabase
            .from("ablation_runs")
            .insert(Insert(id: id,
                           experimentRunId: experimentRunId,
                           blockName: ablation.targetBlock,
                           paramKey: ablation.paramKey,
                           controlValue: ablation.controlValue,
                           testValue: ablation.testValue,
                           sliceDef: ablation.sliceDef))
            .execute()

        // Derive two policies (control/test). For v1, we rely on PolicySelector and override similarity threshold if targeted.
        let policySelector = PolicySelector.shared
        let basePolicy = policySelector.resolvePolicy(familyId: familyId, config: regenConfig)

        func overridePolicy(_ base: ResolvedPolicy, value: String) -> ResolvedPolicy {
            var policy = base
            if ablation.paramKey == "context_extraction.similarity_threshold",
               let val = Double(value) {
                let ctx = policy.promptBlocks.contextExtraction
                let overridden = ContextExtractionParams(
                    enabled: ctx?.enabled ?? true,
                    provider: ctx?.provider ?? "edge",
                    batchSize: ctx?.batchSize,
                    delayMs: ctx?.delayMs,
                    similarityThreshold: val,
                    language: ctx?.language
                )
                policy = ResolvedPolicy(
                    modelProvider: policy.modelProvider,
                    temperature: policy.temperature,
                    topP: policy.topP,
                    seed: policy.seed,
                    guidance: policy.guidance,
                    promptBlocks: PromptBlocks(
                        similarCase: policy.promptBlocks.similarCase,
                        actionTemplate: policy.promptBlocks.actionTemplate,
                        contextExtraction: overridden,
                        relevantInsights: policy.promptBlocks.relevantInsights,
                        analysis: policy.promptBlocks.analysis,
                        translation: policy.promptBlocks.translation
                    )
                )
            }
            return policy
        }

        // Start control run
        try await orchestrator.startRegeneration(
            familyId: familyId,
            config: regenConfig,
            resolvedPolicy: overridePolicy(basePolicy, value: ablation.controlValue)
        )

        // Start test run
        try await orchestrator.startRegeneration(
            familyId: familyId,
            config: regenConfig,
            resolvedPolicy: overridePolicy(basePolicy, value: ablation.testValue)
        )

        return id
    }
}


