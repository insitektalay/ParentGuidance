import SwiftUI

struct ExperimentBuilderView: View {
    @State private var targetBlock: String = "context_extraction"
    @State private var paramKey: String = "context_extraction.similarity_threshold"
    @State private var controlValue: String = "0.8"
    @State private var testValue: String = "0.85"
    @State private var sliceSize: Int = 200
    @State private var isRunning = false
    @EnvironmentObject var appCoordinator: AppCoordinator

    var body: some View {
        Form {
            Section(header: Text("Ablation Target")) {
                TextField("Block", text: $targetBlock)
                TextField("Param Key", text: $paramKey)
                TextField("Control", text: $controlValue)
                TextField("Test", text: $testValue)
                Stepper("Slice Size: \(sliceSize)", value: $sliceSize, in: 50...1000, step: 50)
            }
            Button(action: { Task { await run() } }) {
                Text(isRunning ? "Running…" : "Start")
            }.disabled(isRunning)
        }
        .navigationTitle("Experiment Builder")
    }

    private func run() async {
        guard !isRunning else { return }
        guard let familyIdString = appCoordinator.children.first?.familyId,
              let familyUUID = UUID(uuidString: familyIdString) else { return }
        isRunning = true
        defer { isRunning = false }
        // Create a basic experiment_run
        let config = ExperimentConfig(
            promptTemplates: nil,
            modelProvider: "openai/gpt-4o",
            temperature: 0.3,
            topP: 0.9,
            seed: 42,
            useEdgeFunction: true,
            guidanceStyle: "Warm Practical",
            guidanceMode: "fixed"
        )
        do {
            let run = try await ExperimentRunner.shared.createExperiment(
                familyId: familyUUID,
                name: "Ablation: \(paramKey)",
                description: "Auto-created from ExperimentBuilder",
                config: config,
                runType: .manual,
                dateRange: nil,
                situationFilter: nil
            )
            try await ExperimentRunner.shared.startExperiment(run.id)
        } catch {
        }
    }
}


