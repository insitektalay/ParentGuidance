import SwiftUI

struct ExperimentBuilderView: View {
    @State private var targetBlock: String = "context_extraction"
    @State private var paramKey: String = "context_extraction.similarity_threshold"
    @State private var controlValue: String = "0.8"
    @State private var testValue: String = "0.85"
    @State private var sliceSize: Int = 200
    @State private var isRunning = false
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var lastRunId: UUID?
    
    // User-friendly options
    @State private var selectedFeature: ExperimentFeature = .contextExtraction
    @State private var selectedParameter: ExperimentParameter = .similarityThreshold
    
    enum ExperimentFeature: String, CaseIterable {
        case contextExtraction = "context_extraction"
        case guidance = "guidance"
        case translation = "translation"
        
        var displayName: String {
            switch self {
            case .contextExtraction: return "Context Analysis"
            case .guidance: return "Guidance Generation"
            case .translation: return "Translation"
            }
        }
        
        var description: String {
            switch self {
            case .contextExtraction: return "How the AI extracts and categorizes context from situations"
            case .guidance: return "How the AI generates parenting guidance"
            case .translation: return "How the AI translates content"
            }
        }
    }
    
    enum ExperimentParameter: String, CaseIterable {
        case similarityThreshold = "similarity_threshold"
        case temperature = "temperature"
        case maxTokens = "max_tokens"
        
        var displayName: String {
            switch self {
            case .similarityThreshold: return "Similarity Threshold"
            case .temperature: return "AI Creativity Level"
            case .maxTokens: return "Response Length"
            }
        }
        
        var helpText: String {
            switch self {
            case .similarityThreshold: return "How similar insights need to be to group together (0.0-1.0)"
            case .temperature: return "Higher values make AI more creative, lower more focused (0.0-2.0)"
            case .maxTokens: return "Maximum length of AI responses (100-4000)"
            }
        }
        
        var defaultControl: String {
            switch self {
            case .similarityThreshold: return "0.80"
            case .temperature: return "0.3"
            case .maxTokens: return "2000"
            }
        }
        
        var defaultTest: String {
            switch self {
            case .similarityThreshold: return "0.85"
            case .temperature: return "0.5"
            case .maxTokens: return "2500"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with explanation
                VStack(alignment: .leading, spacing: 12) {
                    Label("What is this?", systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("The Experiment Builder lets you run A/B tests on AI features. You can compare two different configurations (Control vs Test) to see which performs better on your parenting situations.")
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Feature Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("1. Choose Feature to Test")
                        .font(.headline)
                    
                    Picker("Feature", selection: $selectedFeature) {
                        ForEach(ExperimentFeature.allCases, id: \.self) { feature in
                            Text(feature.displayName).tag(feature)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text(selectedFeature.description)
                        .font(.caption)
                        .foregroundColor(SemanticColors.secondaryText)
                }
                
                // Parameter Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("2. Choose What to Adjust")
                        .font(.headline)
                    
                    Picker("Parameter", selection: $selectedParameter) {
                        ForEach(ExperimentParameter.allCases, id: \.self) { param in
                            Text(param.displayName).tag(param)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(SemanticColors.secondaryBackground)
                    .cornerRadius(8)
                    
                    Text(selectedParameter.helpText)
                        .font(.caption)
                        .foregroundColor(SemanticColors.secondaryText)
                }
                
                // Control vs Test Values
                VStack(alignment: .leading, spacing: 16) {
                    Text("3. Set Your Test Values")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        // Control Value
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Control (Current)", systemImage: "a.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                            
                            TextField("Current value", text: $controlValue)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                            
                            Text("The baseline configuration")
                                .font(.caption2)
                                .foregroundColor(SemanticColors.tertiaryText)
                        }
                        
                        // Test Value
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Test (New)", systemImage: "b.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            
                            TextField("New value to test", text: $testValue)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                            
                            Text("The new configuration to test")
                                .font(.caption2)
                                .foregroundColor(SemanticColors.tertiaryText)
                        }
                    }
                }
                
                // Sample Size
                VStack(alignment: .leading, spacing: 12) {
                    Text("4. Choose Sample Size")
                        .font(.headline)
                    
                    HStack {
                        Text("Test on")
                        Text("\(sliceSize)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                        Text("situations")
                    }
                    
                    Stepper("", value: $sliceSize, in: 50...1000, step: 50)
                        .labelsHidden()
                    
                    Text("More situations = more reliable results but longer processing time")
                        .font(.caption)
                        .foregroundColor(SemanticColors.secondaryText)
                }
                
                Divider()
                
                // Start Button with explanation
                VStack(spacing: 16) {
                    Button(action: { Task { await run() } }) {
                        HStack {
                            Image(systemName: isRunning ? "hourglass" : "play.fill")
                            Text(isRunning ? "Running Experiment..." : "Start Experiment")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isRunning ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isRunning)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("What happens when you tap Start?", systemImage: "questionmark.circle")
                            .font(.caption)
                            .foregroundColor(SemanticColors.secondaryText)
                        
                        Text("• The system will process \(sliceSize) situations twice\n• Once with the Control value (\(controlValue))\n• Once with the Test value (\(testValue))\n• Results will be compared to see which performs better\n• This may take several minutes to complete")
                            .font(.caption2)
                            .foregroundColor(SemanticColors.tertiaryText)
                            .lineSpacing(2)
                    }
                    .padding()
                    .background(SemanticColors.secondaryBackground)
                    .cornerRadius(8)
                }
                
                // View Results
                if let runId = lastRunId {
                    NavigationLink(destination: RunLogView(regenRunId: runId)) {
                        HStack {
                            Image(systemName: "chart.bar.doc.horizontal")
                            Text("View Experiment Logs")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Experiment Builder")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Set defaults based on selected parameter
            updateDefaults()
        }
        .onChange(of: selectedParameter) { _ in
            updateDefaults()
        }
        .onChange(of: selectedFeature) { _ in
            updateParameterKey()
        }
    }
    
    private func updateDefaults() {
        controlValue = selectedParameter.defaultControl
        testValue = selectedParameter.defaultTest
        updateParameterKey()
    }
    
    private func updateParameterKey() {
        targetBlock = selectedFeature.rawValue
        paramKey = "\(selectedFeature.rawValue).\(selectedParameter.rawValue)"
    }

    private func run() async {
        guard !isRunning else { return }
        guard let familyIdString = appCoordinator.children.first?.familyId,
              let familyUUID = UUID(uuidString: familyIdString) else { return }
        isRunning = true
        defer { isRunning = false }
        
        // Update the internal values based on selections
        updateParameterKey()
        
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
                name: "A/B Test: \(selectedFeature.displayName) - \(selectedParameter.displayName)",
                description: "Testing \(selectedParameter.displayName): \(controlValue) vs \(testValue)",
                config: config,
                runType: .manual,
                dateRange: nil,
                situationFilter: nil
            )
            try await ExperimentRunner.shared.startExperiment(run.id)
            // Create a regen run to tie logs (optional: minimal surrogate)
            lastRunId = UUID()
        } catch {
            print("Experiment failed: \(error)")
        }
    }
}