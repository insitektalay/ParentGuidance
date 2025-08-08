import SwiftUI

struct RegenAdminView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @StateObject private var orchestrator = RegenOrchestrator()
    @State private var showingConfiguration = false
    @State private var showingResetConfirmation = false
    @State private var config = RegenConfig(
        modelProvider: "openai",
        guidanceStyle: "warm_practical",
        guidanceMode: "fixed",
        similarityThreshold: 0.8,
        familyFilter: nil,
        dateRange: nil,
        determinismSeed: nil,
        experimentRunId: nil
    )
    @State private var searchQuery = ""
    @State private var dateRangeEnabled = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var manualRegenerationMode = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Time Machine title
                Text("Time Machine")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(SemanticColors.primaryText)
                    .padding(.horizontal, 16)
                
                if orchestrator.currentRun != nil {
                    // Active run view
                    activeRunView
                } else {
                    // Configuration view
                    configurationView
                }
                
                // Logs section
                logsSection
            }
            .padding(.top, 16)
            .padding(.bottom, 100) // Space for tab bar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SemanticColors.primaryBackground)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset Family Data", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(manualRegenerationMode ? "Reset Only" : "Reset & Start", role: .destructive) {
                Task {
                    await startRegeneration()
                }
            }
        } message: {
            if manualRegenerationMode {
                Text("This will delete AI-generated content (guidance, insights) for the selected date range. You'll need to manually regenerate each situation from the Library.")
            } else {
                Text("This will permanently delete all AI-generated content (guidance, insights, recommendations) for this family and regenerate them sequentially. User situations will be preserved.")
            }
        }
    }
    
    
    // MARK: - Configuration View
    
    private var configurationView: some View {
        VStack(spacing: 24) {
            // Overview Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Overview")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                    .padding(.horizontal, 16)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Time Machine Regeneration")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(SemanticColors.primaryText)
                            
                            Text("Replay historical situations with new AI parameters")
                                .font(.system(size: 14))
                                .foregroundColor(SemanticColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        if orchestrator.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                }
                .padding(16)
                .background(SemanticColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: colorScheme == .light ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
                .padding(.horizontal, 16)
            }
            
            // Current Family Info
            if let familyId = appCoordinator.currentFamilyId {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Family")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(SemanticColors.primaryText)
                        .padding(.horizontal, 16)
                    
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(SemanticColors.accent)
                        Text("Family ID: \(String(familyId.prefix(8)))...")
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.secondaryText)
                    }
                    .padding(16)
                    .background(SemanticColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: colorScheme == .light ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 16)
                }
            }
            
            // Configuration Settings Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Configuration")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                    .padding(.horizontal, 16)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Model Provider
                    Text("Model Provider")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.secondaryText)
                    
                    Picker("Model Provider", selection: $config.modelProvider) {
                        Text("OpenAI").tag("openai")
                        Text("Anthropic").tag("anthropic")
                        Text("xAI").tag("xai")
                        Text("Google").tag("google")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Divider()
                    
                    // Guidance Style
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Guidance Style")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SemanticColors.secondaryText)
                        
                        Picker("", selection: $config.guidanceStyle) {
                            Text("Warm Practical").tag("warm_practical")
                            Text("Analytical Scientific").tag("analytical_scientific")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Divider()
                    
                    // Guidance Mode
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Structure Mode")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SemanticColors.secondaryText)
                        
                        Picker("", selection: $config.guidanceMode) {
                            Text("Fixed").tag("fixed")
                            Text("Dynamic").tag("dynamic")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Divider()
                    
                    // Date Range
                    Toggle("Filter by Date Range", isOn: $dateRangeEnabled)
                        .font(.system(size: 16))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    if dateRangeEnabled {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                            .font(.system(size: 16))
                            .foregroundColor(SemanticColors.primaryText)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                            .font(.system(size: 16))
                            .foregroundColor(SemanticColors.primaryText)
                    }
                    
                    Divider()
                    
                    // Similarity Threshold
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Similarity Threshold: \(config.similarityThreshold, specifier: "%.2f")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SemanticColors.secondaryText)
                        
                        Slider(value: .init(
                            get: { config.similarityThreshold },
                            set: { config.similarityThreshold = $0 }
                        ), in: 0.5...1.0, step: 0.05)
                            .accentColor(SemanticColors.accent)
                    }
                    
                    Divider()
                    
                    // Manual Regeneration Mode
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $manualRegenerationMode) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Manual Regeneration Mode")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SemanticColors.primaryText)
                                Text("Only wipe guidance, then regenerate manually from Library")
                                    .font(.system(size: 12))
                                    .foregroundColor(SemanticColors.secondaryText)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: SemanticColors.accent))
                        
                        if manualRegenerationMode {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.orange)
                                Text("In manual mode, Time Machine will only delete guidance for the date range. You'll need to regenerate each situation manually from the Library in chronological order.")
                                    .font(.system(size: 12))
                                    .foregroundColor(SemanticColors.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(16)
                .background(SemanticColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: colorScheme == .light ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
                .padding(.horizontal, 16)
            }
            
            // Start Button
            Button(action: {
                showingResetConfirmation = true
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Regeneration")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(appCoordinator.currentFamilyId != nil ? SemanticColors.accent : SemanticColors.tertiaryText.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(appCoordinator.currentFamilyId == nil)
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Active Run View
    
    private var activeRunView: some View {
        VStack(spacing: 24) {
            // Progress Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Progress")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                    .padding(.horizontal, 16)
                
                // Progress Card
                progressCard
            }
            
            // Control Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Controls")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                    .padding(.horizontal, 16)
                
                VStack(spacing: 12) {
                    // Main controls
                    HStack(spacing: 16) {
                        Button(action: {
                            Task {
                                try await orchestrator.pauseRegeneration()
                            }
                        }) {
                            HStack {
                                Image(systemName: "pause.fill")
                                Text("Pause")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorPalette.terracotta)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!orchestrator.isProcessing)
                        
                        Button(action: {
                            Task {
                                if let runId = orchestrator.currentRun?.id {
                                    try await orchestrator.resumeRegeneration(runId: runId)
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Resume")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SemanticColors.accent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(orchestrator.isProcessing)
                    }
                    
                    // Per-situation controls (show when processing)
                    if orchestrator.isProcessing, let run = orchestrator.currentRun {
                        HStack(spacing: 12) {
                            Button(action: {
                                Task {
                                    try await orchestrator.skipCurrentSituation()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "forward.fill")
                                    Text("Skip")
                                }
                                .font(.system(size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(SemanticColors.secondaryBackground)
                                .foregroundColor(SemanticColors.primaryText)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                Task {
                                    try await orchestrator.retryCurrentSituation()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Retry")
                                }
                                .font(.system(size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(SemanticColors.secondaryBackground)
                                .foregroundColor(SemanticColors.primaryText)
                                .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                            if let currentId = run.progress.currentSituationId {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Current:")
                                        .font(.system(size: 10))
                                        .foregroundColor(SemanticColors.tertiaryText)
                                    Text("Situation \\(run.progress.currentSituationIndex + 1)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(SemanticColors.primaryText)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Progress Card
    
    private var progressCard: some View {
        VStack(spacing: 16) {
            if let run = orchestrator.currentRun {
                // Status
                HStack {
                    Circle()
                        .fill(statusColor(for: run.status))
                        .frame(width: 12, height: 12)
                    
                    Text(run.status.rawValue.capitalized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Spacer()
                    
                    Text("\(run.progress.processedSituations)/\(run.progress.totalSituations)")
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                }
                
                // Progress Bar
                ProgressView(value: run.progress.progressPercentage, total: 100)
                    .progressViewStyle(LinearProgressViewStyle())
                    .accentColor(SemanticColors.accent)
                
                // Stats
                HStack(spacing: 20) {
                    statItem(
                        icon: "doc.text",
                        value: "\(run.progress.guidanceGenerated)",
                        label: "Guidance"
                    )
                    
                    statItem(
                        icon: "lightbulb",
                        value: "\(run.progress.insightsExtracted)",
                        label: "Insights"
                    )
                    
                    statItem(
                        icon: "network",
                        value: "\(run.progress.apiCallsMade)",
                        label: "API Calls"
                    )
                    
                    if !run.progress.errors.isEmpty {
                        statItem(
                            icon: "exclamationmark.triangle",
                            value: "\(run.progress.errors.count)",
                            label: "Errors",
                            color: .red
                        )
                    }
                }
                
            }
        }
        .padding(16)
        .background(SemanticColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: colorScheme == .light ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Logs Section
    
    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Logs")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
                
                Button("Clear") {
                    orchestrator.logs.removeAll()
                }
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.accent)
            }
            .padding(.horizontal, 16)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(orchestrator.logs.enumerated()), id: \.offset) { index, log in
                            Text(log)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(SemanticColors.secondaryText)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 200)
                .background(SemanticColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(SemanticColors.tertiaryText.opacity(0.2), lineWidth: 1)
                )
                .onChange(of: orchestrator.logs.count) { _ in
                    withAnimation {
                        proxy.scrollTo(orchestrator.logs.count - 1, anchor: .bottom)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Helper Views
    
    private func statItem(icon: String, value: String, label: String, color: Color? = nil) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color ?? SemanticColors.secondaryText)
                .font(.system(size: 20))
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color ?? SemanticColors.primaryText)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(SemanticColors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func statusColor(for status: RegenRunStatus) -> Color {
        switch status {
        case .running:
            return .green
        case .paused:
            return ColorPalette.terracotta
        case .completed:
            return SemanticColors.accent
        case .failed:
            return .red
        }
    }
    
    // MARK: - Actions
    
    private func startRegeneration() async {
        guard let familyIdString = appCoordinator.currentFamilyId,
              let familyId = UUID(uuidString: familyIdString) else { return }
        
        var finalConfig = config
        if dateRangeEnabled {
            finalConfig.dateRange = DateRange(start: startDate, end: endDate)
        }
        
        if manualRegenerationMode {
            // In manual mode, only reset data without regenerating
            do {
                orchestrator.logs.append("Starting manual regeneration mode...")
                orchestrator.logs.append("This will only delete guidance for the specified date range.")
                
                // Call the date-range selective reset directly
                let response = try await SupabaseManager.shared.client
                    .rpc("reset_family_derived_data_date_range", params: [
                        "p_family_id": familyId.uuidString,
                        "p_regen_run_id": UUID().uuidString,
                        "p_start_date": dateRangeEnabled ? ISO8601DateFormatter().string(from: startDate) : nil,
                        "p_end_date": dateRangeEnabled ? ISO8601DateFormatter().string(from: endDate) : nil
                    ].compactMapValues { $0 })
                    .execute()
                
                let result = try JSONSerialization.jsonObject(with: response.data) as? [String: Any] ?? [:]
                orchestrator.logs.append("✓ Reset complete: \(result)")
                orchestrator.logs.append("Navigate to Library to manually regenerate guidance for each situation.")
                
            } catch {
                orchestrator.logs.append("❌ Manual reset failed: \(error.localizedDescription)")
                print("Failed to perform manual reset: \(error)")
            }
        } else {
            // Normal mode - reset and regenerate automatically
            do {
                try await orchestrator.startRegeneration(
                    familyId: familyId,
                    config: finalConfig
                )
            } catch {
                print("Failed to start regeneration: \(error)")
            }
        }
    }
}

struct RegenAdminView_Previews: PreviewProvider {
    static var previews: some View {
        RegenAdminView()
    }
}