import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class ExperimentExportService: ObservableObject {
    static let shared = ExperimentExportService()
    
    private let supabaseManager = SupabaseManager.shared
    
    private init() {}
    
    // MARK: - Export Types
    
    enum ExportFormat {
        case csv
        case json
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            }
        }
        
        var mimeType: String {
            switch self {
            case .csv: return "text/csv"
            case .json: return "application/json"
            }
        }
    }
    
    // MARK: - Export Functions
    
    /// Export experiment run data
    func exportExperimentRun(runId: UUID, format: ExportFormat) async throws -> URL {
        // Fetch experiment run with all related data
        let runData = try await fetchExperimentRunData(runId: runId)
        
        switch format {
        case .csv:
            return try createCSVExport(from: runData)
        case .json:
            return try createJSONExport(from: runData)
        }
    }
    
    /// Export multiple experiment runs for comparison
    func exportExperimentComparison(runIds: [UUID], format: ExportFormat) async throws -> URL {
        var allRunsData: [ExperimentRunData] = []
        
        for runId in runIds {
            let runData = try await fetchExperimentRunData(runId: runId)
            allRunsData.append(runData)
        }
        
        switch format {
        case .csv:
            return try createComparisonCSVExport(from: allRunsData)
        case .json:
            return try createComparisonJSONExport(from: allRunsData)
        }
    }
    
    // MARK: - Data Fetching
    
    private struct ExperimentRunData {
        let run: ExperimentRun
        let scores: [ExperimentScore]
        let goldResponses: [GoldResponse]
        let redlineResponses: [RedlineResponse]
    }
    
    private func fetchExperimentRunData(runId: UUID) async throws -> ExperimentRunData {
        // Fetch experiment run
        let runResponse = try await supabaseManager.client
            .from("experiment_runs")
            .select()
            .eq("id", value: runId.uuidString)
            .single()
            .execute()
        
        let run = try JSONDecoder().decode(ExperimentRun.self, from: runResponse.data)
        
        // Fetch scores
        let scoresResponse = try await supabaseManager.client
            .from("experiment_scores")
            .select()
            .eq("experiment_run_id", value: runId.uuidString)
            .order("created_at", ascending: true)
            .execute()
        
        let scores = try JSONDecoder().decode([ExperimentScore].self, from: scoresResponse.data)
        
        // Fetch gold responses
        let goldResponse = try await supabaseManager.client
            .from("gold_responses")
            .select()
            .eq("experiment_run_id", value: runId.uuidString)
            .order("created_at", ascending: true)
            .execute()
        
        let goldResponses = try JSONDecoder().decode([GoldResponse].self, from: goldResponse.data)
        
        // Fetch redline responses
        let redlineResponse = try await supabaseManager.client
            .from("redline_responses")
            .select()
            .eq("experiment_run_id", value: runId.uuidString)
            .order("created_at", ascending: true)
            .execute()
        
        let redlineResponses = try JSONDecoder().decode([RedlineResponse].self, from: redlineResponse.data)
        
        return ExperimentRunData(
            run: run,
            scores: scores,
            goldResponses: goldResponses,
            redlineResponses: redlineResponses
        )
    }
    
    // MARK: - CSV Export
    
    private func createCSVExport(from data: ExperimentRunData) throws -> URL {
        var csvContent = "Experiment Run Export\n"
        csvContent += "Run ID,\(data.run.id)\n"
        csvContent += "Name,\(data.run.name)\n"
        csvContent += "Model Provider,\(data.run.config.modelProvider)\n"
        csvContent += "Guidance Style,\(data.run.config.guidanceStyle)\n"
        csvContent += "Guidance Mode,\(data.run.config.guidanceMode)\n"
        csvContent += "Started At,\(formatDate(data.run.startedAt ?? Date()))\n"
        csvContent += "Completed At,\(formatDate(data.run.completedAt ?? data.run.startedAt ?? Date()))\n"
        csvContent += "Status,\(data.run.status.rawValue)\n"
        csvContent += "\n"
        
        // Scores section
        csvContent += "Experiment Scores\n"
        csvContent += "Situation ID,Semantic Similarity,String Overlap,Style Tone,Redline Penalty,Composite Score,Created At\n"
        
        for score in data.scores {
            csvContent += "\(score.situationId),\(score.semanticSimilarity ?? 0),\(score.stringOverlap ?? 0),\(score.styleToneScore ?? 0),\(score.redlinePenalty ?? 0),\(score.compositeScore),\(formatDate(score.createdAt))\n"
        }
        
        csvContent += "\n"
        
        // Summary statistics
        let avgCompositeScore = data.scores.map { $0.compositeScore }.reduce(0, +) / Double(data.scores.count)
        let avgSemanticSimilarity = data.scores.compactMap { $0.semanticSimilarity }.reduce(0, +) / Double(max(data.scores.compactMap { $0.semanticSimilarity }.count, 1))
        let avgRedlinePenalty = data.scores.compactMap { $0.redlinePenalty }.reduce(0, +) / Double(max(data.scores.compactMap { $0.redlinePenalty }.count, 1))
        
        csvContent += "Summary Statistics\n"
        csvContent += "Total Situations,\(data.scores.count)\n"
        csvContent += "Average Composite Score,\(String(format: "%.2f", avgCompositeScore))\n"
        csvContent += "Average Semantic Similarity,\(String(format: "%.2f", avgSemanticSimilarity))\n"
        csvContent += "Average Redline Penalty,\(String(format: "%.2f", avgRedlinePenalty))\n"
        
        // Save to file
        let fileName = "experiment_\(data.run.id)_\(Date().timeIntervalSince1970).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func createComparisonCSVExport(from runs: [ExperimentRunData]) throws -> URL {
        var csvContent = "Experiment Comparison Export\n"
        csvContent += "Generated At,\(formatDate(Date()))\n\n"
        
        // Header row
        csvContent += "Run Name,Model Provider,Style,Mode,Started At,Status,Avg Composite Score,Avg Semantic Similarity,Avg Redline Penalty,Total Situations\n"
        
        // Data rows
        for runData in runs {
            let scores = runData.scores
            let avgComposite = scores.compactMap { $0.compositeScore }.reduce(0, +) / Double(max(scores.count, 1))
            let avgSemantic = scores.compactMap { $0.semanticSimilarity }.reduce(0, +) / Double(max(scores.compactMap { $0.semanticSimilarity }.count, 1))
            let avgRedline = scores.compactMap { $0.redlinePenalty }.reduce(0, +) / Double(max(scores.count, 1))
            
            csvContent += "\"\(runData.run.name)\",\(runData.run.config.modelProvider),\(runData.run.config.guidanceStyle),\(runData.run.config.guidanceMode),\(formatDate(runData.run.startedAt ?? Date())),\(runData.run.status.rawValue),\(String(format: "%.2f", avgComposite)),\(String(format: "%.2f", avgSemantic)),\(String(format: "%.2f", avgRedline)),\(scores.count)\n"
        }
        
        // Save to file
        let fileName = "experiment_comparison_\(Date().timeIntervalSince1970).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    // MARK: - JSON Export
    
    private func createJSONExport(from data: ExperimentRunData) throws -> URL {
        struct ExportData: Encodable {
            let exportDate: Date
            let run: ExperimentRun
            let scores: [ExperimentScore]
            let goldResponses: [GoldResponse]
            let redlineResponses: [RedlineResponse]
            let summary: Summary
            
            struct Summary: Encodable {
                let totalSituations: Int
                let averageCompositeScore: Double
                let averageSemanticSimilarity: Double
                let averageRedlinePenalty: Double
            }
        }
        
        let avgCompositeScore = data.scores.compactMap { $0.compositeScore }.reduce(0, +) / Double(max(data.scores.count, 1))
        let avgSemanticSimilarity = data.scores.compactMap { $0.semanticSimilarity }.reduce(0, +) / Double(max(data.scores.compactMap { $0.semanticSimilarity }.count, 1))
        let avgRedlinePenalty = data.scores.compactMap { $0.redlinePenalty }.reduce(0, +) / Double(max(data.scores.compactMap { $0.redlinePenalty }.count, 1))
        
        let exportData = ExportData(
            exportDate: Date(),
            run: data.run,
            scores: data.scores,
            goldResponses: data.goldResponses,
            redlineResponses: data.redlineResponses,
            summary: ExportData.Summary(
                totalSituations: data.scores.count,
                averageCompositeScore: avgCompositeScore,
                averageSemanticSimilarity: avgSemanticSimilarity,
                averageRedlinePenalty: avgRedlinePenalty
            )
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(exportData)
        
        // Save to file
        let fileName = "experiment_\(data.run.id)_\(Date().timeIntervalSince1970).json"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try jsonData.write(to: fileURL)
        return fileURL
    }
    
    private func createComparisonJSONExport(from runs: [ExperimentRunData]) throws -> URL {
        struct ComparisonExport: Encodable {
            let exportDate: Date
            let runs: [RunSummary]
            
            struct RunSummary: Encodable {
                let runId: UUID
                let name: String
                let config: ExperimentConfig
                let startedAt: Date
                let completedAt: Date?
                let status: String
                let summary: Statistics
                
                struct Statistics: Encodable {
                    let totalSituations: Int
                    let averageCompositeScore: Double
                    let averageSemanticSimilarity: Double
                    let averageRedlinePenalty: Double
                }
            }
        }
        
        let runSummaries = runs.map { runData in
            let scores = runData.scores
            let avgComposite = scores.compactMap { $0.compositeScore }.reduce(0, +) / Double(max(scores.count, 1))
            let avgSemantic = scores.compactMap { $0.semanticSimilarity }.reduce(0, +) / Double(max(scores.compactMap { $0.semanticSimilarity }.count, 1))
            let avgRedline = scores.compactMap { $0.redlinePenalty }.reduce(0, +) / Double(max(scores.count, 1))
            
            return ComparisonExport.RunSummary(
                runId: runData.run.id,
                name: runData.run.name,
                config: runData.run.config,
                startedAt: runData.run.startedAt ?? Date(),
                completedAt: runData.run.completedAt,
                status: runData.run.status.rawValue,
                summary: ComparisonExport.RunSummary.Statistics(
                    totalSituations: scores.count,
                    averageCompositeScore: avgComposite,
                    averageSemanticSimilarity: avgSemantic,
                    averageRedlinePenalty: avgRedline
                )
            )
        }
        
        let exportData = ComparisonExport(
            exportDate: Date(),
            runs: runSummaries
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(exportData)
        
        // Save to file
        let fileName = "experiment_comparison_\(Date().timeIntervalSince1970).json"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try jsonData.write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}