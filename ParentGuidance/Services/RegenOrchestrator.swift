import Foundation
import Supabase

@MainActor
class RegenOrchestrator: ObservableObject {
    @Published var currentRun: RegenRun?
    @Published var isProcessing = false
    @Published var error: String?
    @Published var logs: [String] = []
    
    private let supabaseManager = SupabaseManager.shared
    private let conversationService = ConversationService.shared
    private let contextualInsightService = ContextualInsightService.shared
    private let relevantInsightsService = RelevantInsightsService.shared
    private let frameworkGenerationService = FrameworkGenerationService.shared
    
    private var processingTask: Task<Void, Never>?
    
    // MARK: - Public Methods
    
    func startRegeneration(
        familyId: UUID,
        config: RegenConfig,
        resolvedPolicy: ResolvedPolicy? = nil
    ) async throws {
        // Check if there's already a running regen for this family
        let existingRuns = try await supabaseManager.client
            .from("regen_runs")
            .select()
            .eq("family_id", value: familyId.uuidString)
            .eq("status", value: RegenRunStatus.running.rawValue)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let runs = try decoder.decode([RegenRun].self, from: existingRuns.data)
        
        guard runs.isEmpty else {
            throw RegenError.alreadyRunning
        }
        
        // Reset derived data
        log("Resetting derived data for family...")
        let resetResult = try await resetFamilyData(familyId: familyId, config: config)
        log("Reset complete: \(resetResult)")
        
        // Create new regen run
        let initialProgress = RegenProgress(
            totalSituations: 0,
            processedSituations: 0,
            currentSituationId: nil,
            currentSituationIndex: 0,
            guidanceGenerated: 0,
            insightsExtracted: 0,
            apiCallsMade: 0,
            errors: []
        )
        
        struct RegenRunInsert: Encodable {
            let familyId: String
            let status: String
            let config: RegenConfig
            let progress: RegenProgress
            let createdBy: String?
            
            enum CodingKeys: String, CodingKey {
                case familyId = "family_id"
                case status
                case config
                case progress
                case createdBy = "created_by"
            }
        }
        
        let runData = RegenRunInsert(
            familyId: familyId.uuidString,
            status: RegenRunStatus.running.rawValue,
            config: config,
            progress: initialProgress,
            createdBy: supabaseManager.getCurrentUserId()?.uuidString
        )
        
        let response = try await supabaseManager.client
            .from("regen_runs")
            .insert(runData)
            .select()
            .single()
            .execute()
        
        currentRun = try decoder.decode(RegenRun.self, from: response.data)
        
        // Start processing
        isProcessing = true
        processingTask = Task {
            await processRegeneration(resolvedPolicy: resolvedPolicy)
        }
    }
    
    func pauseRegeneration() async throws {
        guard let runId = currentRun?.id else { return }
        
        processingTask?.cancel()
        
        try await supabaseManager.client
            .from("regen_runs")
            .update(["status": RegenRunStatus.paused.rawValue])
            .eq("id", value: runId.uuidString)
            .execute()
        
        isProcessing = false
        log("Regeneration paused")
    }
    
    func resumeRegeneration(runId: UUID) async throws {
        let response = try await supabaseManager.client
            .from("regen_runs")
            .select()
            .eq("id", value: runId.uuidString)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        currentRun = try decoder.decode(RegenRun.self, from: response.data)
        
        isProcessing = true
        processingTask = Task {
            await processRegeneration()
        }
    }
    
    // MARK: - Private Methods
    
    private func resetFamilyData(familyId: UUID, config: RegenConfig) async throws -> [String: Any] {
        // Use date-range selective reset if date range is specified
        if let dateRange = config.dateRange {
            log("  → Calling reset_family_derived_data_date_range function with date range...")
            log("    Date range: \(ISO8601DateFormatter().string(from: dateRange.start)) to \(ISO8601DateFormatter().string(from: dateRange.end))")
            
            do {
                let response = try await supabaseManager.client
                    .rpc("reset_family_derived_data_date_range", params: [
                        "p_family_id": familyId.uuidString,
                        "p_regen_run_id": currentRun?.id.uuidString ?? UUID().uuidString,
                        "p_start_date": ISO8601DateFormatter().string(from: dateRange.start),
                        "p_end_date": ISO8601DateFormatter().string(from: dateRange.end)
                    ])
                    .execute()
                
                let result = try JSONSerialization.jsonObject(with: response.data) as? [String: Any] ?? [:]
                log("  ✓ Date-range selective database reset completed successfully")
                return result
                
            } catch {
                log("  ❌ Date-range selective database reset failed: \(error.localizedDescription)")
                throw error
            }
        } else {
            log("  → Calling reset_family_derived_data function (full family reset)...")
            
            do {
                let response = try await supabaseManager.client
                    .rpc("reset_family_derived_data", params: [
                        "p_family_id": familyId.uuidString,
                        "p_regen_run_id": currentRun?.id.uuidString ?? UUID().uuidString
                    ])
                    .execute()
                
                let result = try JSONSerialization.jsonObject(with: response.data) as? [String: Any] ?? [:]
                log("  ✓ Full family database reset completed successfully")
                return result
                
            } catch {
                log("  ❌ Full family database reset failed: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    private func processRegeneration(resolvedPolicy: ResolvedPolicy?) async {
        guard let run = currentRun else { return }
        
        do {
            // Fetch all situations for the family
            let situations = try await fetchSituations(familyId: run.familyId, config: run.config)
            
            // Update total count
            var progress = run.progress
            progress.totalSituations = situations.count
            try await updateProgress(progress)
            
            if situations.isEmpty {
                log("No situations found in the specified criteria. Completing regeneration.")
                try await completeRegeneration()
                return
            }
            
            log("Starting regeneration for \(situations.count) situations")
            
            // Process each situation sequentially
            for (index, situation) in situations.enumerated() {
                if Task.isCancelled { break }
                
                progress.currentSituationId = UUID(uuidString: situation.id)
                progress.currentSituationIndex = index
                try await updateProgress(progress)
                
                log("Processing situation \(index + 1)/\(situations.count): \(situation.description.prefix(50))...")
                
                do {
                    // Generate guidance
                    log("  → Generating guidance...")
                    let guidance = try await generateGuidance(
                        for: situation,
                        config: run.config,
                        runId: run.id
                    )
                    log("  ✓ Guidance generated (ID: \(guidance.id))")
                    progress.guidanceGenerated += 1
                    progress.apiCallsMade += 1
                    
                    // Extract insights
                    let contextEnabled = resolvedPolicy?.promptBlocks.contextExtraction?.enabled ?? UserDefaults.standard.bool(forKey: "aiProcessingContextExtraction")
                    if contextEnabled {
                        log("  → Extracting contextual insights...")
                        try await extractInsights(
                            for: situation,
                            config: run.config,
                            runId: run.id
                        )
                        log("  ✓ Insights extracted")
                        progress.insightsExtracted += 1
                        progress.apiCallsMade += 1
                    } else {
                        log("  ⏭ Skipping insight extraction (disabled)")
                    }
                    
                    // Match relevant insights (only from prior situations)  
                    let relevantEnabled = resolvedPolicy?.promptBlocks.relevantInsights?.enabled ?? UserDefaults.standard.bool(forKey: "aiProcessingRelevantInsights")
                    if relevantEnabled {
                        log("  → Matching relevant insights...")
                        try await matchRelevantInsights(
                            for: situation,
                            priorToDate: Date(),
                            runId: run.id
                        )
                        log("  ✓ Relevant insights matched")
                    } else {
                        log("  ⏭ Skipping relevant insights matching (disabled)")
                    }
                    
                    progress.processedSituations += 1
                    try await updateProgress(progress)
                    
                    log("✓ Completed situation \(index + 1)/\(situations.count)")
                    
                    // Rate limiting
                    log("  ⏱ Waiting 1 second before next situation...")
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                    
                } catch {
                    log("❌ Error processing situation \(situation.id): \(error.localizedDescription)")
                    progress.errors.append(ProcessingError(
                        situationId: UUID(uuidString: situation.id) ?? UUID(),
                        errorType: String(describing: type(of: error)),
                        message: error.localizedDescription,
                        timestamp: Date()
                    ))
                    try await updateProgress(progress)
                }
            }
            
            log("🎉 All situations processed! Marking regeneration as complete...")
            
            // Mark as completed
            try await completeRegeneration()
            
        } catch {
            log("Fatal error in regeneration: \(error.localizedDescription)")
            try? await failRegeneration(error: error.localizedDescription)
        }
    }
    
    private func fetchSituations(familyId: UUID, config: RegenConfig) async throws -> [Situation] {
        let response = try await supabaseManager.client
            .from("situations")
            .select()
            .eq("family_id", value: familyId.uuidString)
            .order("created_at", ascending: true)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let allSituations = try decoder.decode([Situation].self, from: response.data)
        
        log("Fetched \(allSituations.count) total situations for family")
        
        // Apply date range filter if specified
        if let dateRange = config.dateRange {
            // Extend end date to include the entire day (end of day)
            let calendar = Calendar.current
            let endOfEndDate = calendar.dateInterval(of: .day, for: dateRange.end)?.end ?? dateRange.end
            
            let startDateString = ISO8601DateFormatter().string(from: dateRange.start)
            let endDateString = ISO8601DateFormatter().string(from: endOfEndDate)
            
            log("Applying date filter: \(startDateString) to \(endDateString)")
            
            let filteredSituations = allSituations.filter { situation in
                guard let createdAt = ISO8601DateFormatter().date(from: situation.createdAt) else {
                    log("Warning: Could not parse date for situation \(situation.id): \(situation.createdAt)")
                    return false
                }
                return createdAt >= dateRange.start && createdAt < endOfEndDate
            }
            
            log("Filtered to \(filteredSituations.count) situations in date range")
            return filteredSituations
        }
        
        log("No date filter applied, returning all \(allSituations.count) situations")
        return allSituations
    }
    
    private func generateGuidance(
        for situation: Situation,
        config: RegenConfig,
        runId: UUID
    ) async throws -> Guidance {
        // Set the model provider and style in UserDefaults temporarily
        let originalProvider = UserDefaults.standard.string(forKey: "selectedModelProvider")
        let originalStyle = UserDefaults.standard.string(forKey: "guidanceStyle")
        let originalMode = UserDefaults.standard.string(forKey: "guidanceMode")
        
        UserDefaults.standard.set(config.modelProvider, forKey: "selectedModelProvider")
        UserDefaults.standard.set(config.guidanceStyle, forKey: "guidanceStyle")
        UserDefaults.standard.set(config.guidanceMode, forKey: "guidanceMode")
        
        defer {
            // Restore original settings
            if let originalProvider = originalProvider {
                UserDefaults.standard.set(originalProvider, forKey: "selectedModelProvider")
            }
            if let originalStyle = originalStyle {
                UserDefaults.standard.set(originalStyle, forKey: "guidanceStyle")
            }
            if let originalMode = originalMode {
                UserDefaults.standard.set(originalMode, forKey: "guidanceMode")
            }
        }
        
        // Generate guidance using conversation service
        return try await conversationService.generateGuidance(
            situationId: UUID(uuidString: situation.id) ?? UUID(),
            situationText: situation.description,
            childName: "your child",
            regenRunId: runId,
            experimentRunId: config.experimentRunId
        )
    }
    
    private func extractInsights(
        for situation: Situation,
        config: RegenConfig,
        runId: UUID
    ) async throws {
        // Extract contextual insights
        try await contextualInsightService.extractContextualInsights(
            situationId: UUID(uuidString: situation.id) ?? UUID(),
            situationText: situation.description,
            regenRunId: runId,
            experimentRunId: config.experimentRunId
        )
        
        // Extract regulation insights if enabled
        if UserDefaults.standard.bool(forKey: "aiProcessingRegulationInsights") {
            try await contextualInsightService.extractRegulationInsights(
                situationId: UUID(uuidString: situation.id) ?? UUID(),
                situationText: situation.description,
                childName: "your child",
                regenRunId: runId,
                experimentRunId: config.experimentRunId
            )
        }
    }
    
    private func matchRelevantInsights(
        for situation: Situation,
        priorToDate: Date,
        runId: UUID
    ) async throws {
        try await relevantInsightsService.selectRelevantInsightsForHistoricalSituation(
            situationId: UUID(uuidString: situation.id) ?? UUID(),
            priorToDate: priorToDate,
            regenRunId: runId
        )
    }
    
    private func updateProgress(_ progress: RegenProgress) async throws {
        guard let runId = currentRun?.id else { return }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let progressData = try encoder.encode(progress)
        let progressJSON = try JSONSerialization.jsonObject(with: progressData) as? [String: Any] ?? [:]
        
        struct ProgressUpdate: Encodable {
            let progress: RegenProgress
        }
        
        let updateData = ProgressUpdate(progress: progress)
        try await supabaseManager.client
            .from("regen_runs")
            .update(updateData)
            .eq("id", value: runId.uuidString)
            .execute()
        
        // Update local state - create new RegenRun with updated progress
        if let run = currentRun {
            currentRun = RegenRun(
                id: run.id,
                familyId: run.familyId,
                status: run.status,
                config: run.config,
                progress: progress,
                startedAt: run.startedAt,
                completedAt: run.completedAt,
                errorMessage: run.errorMessage,
                createdBy: run.createdBy,
                createdAt: run.createdAt,
                updatedAt: run.updatedAt
            )
        }
    }
    
    private func completeRegeneration() async throws {
        guard let runId = currentRun?.id else { return }
        
        try await supabaseManager.client
            .from("regen_runs")
            .update([
                "status": RegenRunStatus.completed.rawValue,
                "completed_at": Date().ISO8601Format()
            ])
            .eq("id", value: runId.uuidString)
            .execute()
        
        isProcessing = false
        log("Regeneration completed successfully!")
    }
    
    private func failRegeneration(error: String) async throws {
        guard let runId = currentRun?.id else { return }
        
        try await supabaseManager.client
            .from("regen_runs")
            .update([
                "status": RegenRunStatus.failed.rawValue,
                "error_message": error,
                "completed_at": Date().ISO8601Format()
            ])
            .eq("id", value: runId.uuidString)
            .execute()
        
        isProcessing = false
        self.error = error
    }
    
    // MARK: - Individual Situation Controls
    
    func skipCurrentSituation() async throws {
        guard let run = currentRun else { return }
        
        log("Skipping current situation")
        
        // Update progress in database
        let newProcessedSituations = run.progress.processedSituations + 1
        let newIndex = run.progress.currentSituationIndex + 1
        
        let progressData = [
            "processed_situations": newProcessedSituations,
            "current_situation_index": newIndex
        ]
        
        try await supabaseManager.client
            .from("regen_runs")
            .update(["progress": progressData])
            .eq("id", value: run.id.uuidString)
            .execute()
        
        // Check if we're done
        if newProcessedSituations >= run.progress.totalSituations {
            try await supabaseManager.client
                .from("regen_runs")
                .update([
                    "status": "completed",
                    "completed_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: run.id.uuidString)
                .execute()
            
            processingTask?.cancel()
            processingTask = nil
            isProcessing = false
            log("Regeneration completed - all situations processed")
        } else {
            log("Moving to next situation (\(newProcessedSituations + 1)/\(run.progress.totalSituations))")
        }
        
        // Reload the run data
        await loadCurrentRun(runId: run.id)
    }
    
    func retryCurrentSituation() async throws {
        guard let run = currentRun else { return }
        
        log("Retrying current situation")
        
        // Remove the last error if it exists
        var newErrors = run.progress.errors
        if !newErrors.isEmpty {
            newErrors.removeLast()
        }
        
        let progressData = [
            "errors": try JSONEncoder().encode(newErrors)
        ]
        
        try await supabaseManager.client
            .from("regen_runs")
            .update(["progress": progressData])
            .eq("id", value: run.id.uuidString)
            .execute()
        
        log("Retrying situation processing")
        
        // Reload the run data
        await loadCurrentRun(runId: run.id)
    }
    
    private func loadCurrentRun(runId: UUID) async {
        do {
            let response = try await supabaseManager.client
                .from("regen_runs")
                .select()
                .eq("id", value: runId.uuidString)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let updatedRun = try decoder.decode(RegenRun.self, from: response.data)
            
            await MainActor.run {
                self.currentRun = updatedRun
            }
        } catch {
            log("Failed to reload run data: \(error)")
        }
    }
    
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"
        logs.append(logMessage)
        
        // Keep only last 100 logs
        if logs.count > 100 {
            logs.removeFirst()
        }
    }
}

// MARK: - Error Types

enum RegenError: LocalizedError {
    case alreadyRunning
    case noSituations
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .alreadyRunning:
            return "A regeneration is already running for this family"
        case .noSituations:
            return "No situations found matching the criteria"
        case .invalidConfiguration:
            return "Invalid regeneration configuration"
        }
    }
}