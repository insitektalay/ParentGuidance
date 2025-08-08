import Foundation
import Supabase

@MainActor
final class ExperimentLeaderboardService: ObservableObject {
    static let shared = ExperimentLeaderboardService()
    private init() {}

    private let client = SupabaseManager.shared.client

    struct Entry: Identifiable {
        let id: UUID
        let name: String
        let averageComposite: Double
        let confidenceLow: Double
        let confidenceHigh: Double
        let situationsProcessed: Int
        let completedAt: Date?
        let winRate: Double
    }

    func getLeaderboard(familyId: UUID) async throws -> [Entry] {
        // Fetch completed experiment runs for family
        let runsResp = try await client
            .from("experiment_runs")
            .select()
            .eq("family_id", value: familyId.uuidString)
            .eq("status", value: ExperimentStatus.completed.rawValue)
            .execute()
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let runs = try decoder.decode([ExperimentRun].self, from: runsResp.data)
        guard !runs.isEmpty else { return [] }

        var entries: [Entry] = []
        for run in runs {
            let scoresResp = try await client
                .from("experiment_scores")
                .select()
                .eq("experiment_run_id", value: run.id.uuidString)
                .execute()
            let scores = try decoder.decode([ExperimentScore].self, from: scoresResp.data)
            guard !scores.isEmpty else { continue }
            let comps = scores.map { $0.compositeScore }
            let avg = comps.reduce(0, +) / Double(comps.count)
            let (lo, hi) = ci95(comps)
            let wins = comps.filter { $0 >= avg }.count
            let winRate = Double(wins) / Double(comps.count)
            entries.append(Entry(id: run.id, name: run.name, averageComposite: avg, confidenceLow: lo, confidenceHigh: hi, situationsProcessed: scores.count, completedAt: run.completedAt, winRate: winRate))
        }
        return entries.sorted { $0.averageComposite > $1.averageComposite }
    }

    private func ci95(_ values: [Double]) -> (Double, Double) {
        guard values.count > 1 else { return (0, 0) }
        let mean = values.reduce(0,+)/Double(values.count)
        let varSum = values.map { pow($0 - mean, 2) }.reduce(0,+)
        let std = sqrt(varSum / Double(values.count - 1))
        let se = std / sqrt(Double(values.count))
        let margin = 1.96 * se
        return (mean - margin, mean + margin)
    }
}


