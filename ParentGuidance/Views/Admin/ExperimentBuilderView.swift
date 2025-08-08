import SwiftUI

struct ExperimentBuilderView: View {
    @State private var targetBlock: String = "context_extraction"
    @State private var paramKey: String = "context_extraction.similarity_threshold"
    @State private var controlValue: String = "0.8"
    @State private var testValue: String = "0.85"
    @State private var sliceSize: Int = 200
    @State private var isRunning = false

    var body: some View {
        Form {
            Section(header: Text("Ablation Target")) {
                TextField("Block", text: $targetBlock)
                TextField("Param Key", text: $paramKey)
                TextField("Control", text: $controlValue)
                TextField("Test", text: $testValue)
                Stepper("Slice Size: \(sliceSize)", value: $sliceSize, in: 50...1000, step: 50)
            }
            Button(action: { isRunning = true }) {
                Text(isRunning ? "Running…" : "Start")
            }.disabled(isRunning)
        }
        .navigationTitle("Experiment Builder")
    }
}


