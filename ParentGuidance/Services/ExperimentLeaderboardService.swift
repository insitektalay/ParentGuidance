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
        let situationsProcessed: Int
        let completedAt: Date?
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
            let avg = scores.map { $0.compositeScore }.reduce(0, +) / Double(scores.count)
            entries.append(Entry(id: run.id, name: run.name, averageComposite: avg, situationsProcessed: scores.count, completedAt: run.completedAt))
        }
        return entries.sorted { $0.averageComposite > $1.averageComposite }
    }
}


