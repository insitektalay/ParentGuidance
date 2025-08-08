import SwiftUI

struct ExperimentLeaderboardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var exportService = ExperimentExportService.shared
    
    @State private var experimentRuns: [ExperimentRun] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedRuns: Set<UUID> = []
    @State private var sortOption: SortOption = .compositeScore
    @State private var showingExportOptions = false
    @State private var exportFormat: ExperimentExportService.ExportFormat = .csv
    
    enum SortOption: String, CaseIterable {
        case compositeScore = "Composite Score"
        case goldScore = "Gold Score"
        case redlinePenalty = "Redline Penalty"
        case date = "Date"
        case name = "Name"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                if isLoading {
                    ProgressView("Loading experiments...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    errorView(error)
                } else if experimentRuns.isEmpty {
                    emptyView
                } else {
                    // Sort control
                    sortControl
                    
                    // Leaderboard list
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(sortedRuns) { run in
                                ExperimentRunCard(
                                    run: run,
                                    rank: getRank(for: run),
                                    isSelected: selectedRuns.contains(run.id),
                                    onToggleSelection: {
                                        toggleSelection(run.id)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(SemanticColors.primaryBackground)
            .onAppear {
                loadExperimentRuns()
            }
            .sheet(isPresented: $showingExportOptions) {
                exportOptionsSheet
            }
        }
    }
    
    // MARK: - Views
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                }
                
                Spacer()
                
                Text("Experiment Leaderboard")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
                
                if !selectedRuns.isEmpty {
                    Button(action: { showingExportOptions = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export (\(selectedRuns.count))")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.accent)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            // Selection controls
            if !experimentRuns.isEmpty {
                HStack {
                    Button(action: selectAll) {
                        Text("Select All")
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.accent)
                    }
                    
                    Spacer()
                    
                    if !selectedRuns.isEmpty {
                        Button(action: { selectedRuns.removeAll() }) {
                            Text("Clear Selection")
                                .font(.system(size: 14))
                                .foregroundColor(SemanticColors.secondaryText)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
        .background(SemanticColors.primaryBackground)
        .shadow(color: colorScheme == .light ? Color.black.opacity(0.05) : Color.clear, radius: 2, y: 2)
    }
    
    private var sortControl: some View {
        HStack {
            Text("Sort by:")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.secondaryText)
            
            Picker("Sort", selection: $sortOption) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .accentColor(SemanticColors.accent)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundColor(SemanticColors.tertiaryText)
            
            Text("No experiments yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            Text("Run some experiments to see the leaderboard")
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Color.orange)
            
            Text("Failed to load experiments")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                loadExperimentRuns()
            }
            .foregroundColor(SemanticColors.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var exportOptionsSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Export \(selectedRuns.count) experiment\(selectedRuns.count == 1 ? "" : "s")")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                // Format selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Format")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.secondaryText)
                    
                    Picker("Export Format", selection: $exportFormat) {
                        Text("CSV").tag(ExperimentExportService.ExportFormat.csv)
                        Text("JSON").tag(ExperimentExportService.ExportFormat.json)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Export type description
                VStack(alignment: .leading, spacing: 8) {
                    if selectedRuns.count == 1 {
                        Label("Detailed export with all scores and responses", systemImage: "doc.text")
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.secondaryText)
                    } else {
                        Label("Comparison export with summary statistics", systemImage: "chart.bar")
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        showingExportOptions = false
                    }
                    .foregroundColor(SemanticColors.secondaryText)
                    
                    Button(action: performExport) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SemanticColors.accent)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Computed Properties
    
    private var sortedRuns: [ExperimentRun] {
        experimentRuns.sorted { run1, run2 in
            switch sortOption {
            case .compositeScore:
                let score1 = run1.progress.averageCompositeScore ?? 0
                let score2 = run2.progress.averageCompositeScore ?? 0
                return score1 > score2
            case .goldScore:
                // Would need to calculate from scores
                return run1.name < run2.name
            case .redlinePenalty:
                // Would need to calculate from scores
                return run1.name < run2.name
            case .date:
                return (run1.startedAt ?? Date.distantPast) > (run2.startedAt ?? Date.distantPast)
            case .name:
                return run1.name < run2.name
            }
        }
    }
    
    private func getRank(for run: ExperimentRun) -> Int {
        guard let index = sortedRuns.firstIndex(where: { $0.id == run.id }) else { return 0 }
        return index + 1
    }
    
    // MARK: - Actions
    
    private func loadExperimentRuns() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await SupabaseManager.shared.client
                    .from("experiment_runs")
                    .select()
                    .order("started_at", ascending: false)
                    .execute()
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                experimentRuns = try decoder.decode([ExperimentRun].self, from: response.data)
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func toggleSelection(_ runId: UUID) {
        if selectedRuns.contains(runId) {
            selectedRuns.remove(runId)
        } else {
            selectedRuns.insert(runId)
        }
    }
    
    private func selectAll() {
        selectedRuns = Set(experimentRuns.map { $0.id })
    }
    
    private func performExport() {
        Task {
            do {
                let fileURL: URL
                
                if selectedRuns.count == 1, let runId = selectedRuns.first {
                    fileURL = try await exportService.exportExperimentRun(runId: runId, format: exportFormat)
                } else {
                    fileURL = try await exportService.exportExperimentComparison(runIds: Array(selectedRuns), format: exportFormat)
                }
                
                // Present share sheet
                await MainActor.run {
                    showingExportOptions = false
                    presentShareSheet(for: fileURL)
                }
            } catch {
                print("Export failed: \(error)")
            }
        }
    }
    
    private func presentShareSheet(for url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Experiment Run Card

struct ExperimentRunCard: View {
    let run: ExperimentRun
    let rank: Int
    let isSelected: Bool
    let onToggleSelection: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank badge
            rankBadge
            
            // Run info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(run.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Spacer()
                    
                    statusBadge
                }
                
                HStack(spacing: 16) {
                    Label(run.config.modelProvider.capitalized, systemImage: "cpu")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.secondaryText)
                    
                    Label("\(run.config.guidanceStyle) + \(run.config.guidanceMode)", systemImage: "text.alignleft")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.secondaryText)
                }
                
                // Scores
                HStack(spacing: 24) {
                    scoreItem(
                        label: "Composite",
                        value: run.progress.averageCompositeScore ?? 0,
                        color: SemanticColors.accent
                    )
                    
                    scoreItem(
                        label: "Situations",
                        value: Double(run.progress.totalSituations),
                        color: SemanticColors.secondaryText,
                        format: "%.0f"
                    )
                    
                    Spacer()
                    
                    Text(formatDate(run.startedAt ?? Date()))
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.tertiaryText)
                }
            }
            
            // Selection checkbox
            Button(action: onToggleSelection) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? SemanticColors.accent : SemanticColors.secondaryText)
            }
        }
        .padding(16)
        .background(isSelected ? SemanticColors.accent.opacity(0.1) : SemanticColors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? SemanticColors.accent : SemanticColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .if(colorScheme == .light) { view in
            view.cardShadow()
        }
    }
    
    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(rankColor)
                .frame(width: 40, height: 40)
            
            Text("#\(rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return Color.orange
        case 2: return Color.gray
        case 3: return Color.brown
        default: return SemanticColors.secondaryText
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(run.status.rawValue.capitalized)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch run.status {
        case .completed: return Color.green
        case .running: return SemanticColors.accent
        case .failed: return Color.red
        default: return SemanticColors.secondaryText
        }
    }
    
    private func scoreItem(label: String, value: Double, color: Color, format: String = "%.1f") -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(SemanticColors.tertiaryText)
            
            Text(String(format: format, value))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ExperimentLeaderboardView()
}