import Foundation
import Supabase

@MainActor
final class ExperimentScoreService {
    static let shared = ExperimentScoreService()
    private init() {}

    private let client = SupabaseManager.shared.client

    func latestScore(for situationId: UUID) async throws -> ExperimentScore? {
        let resp = try await client
            .from("experiment_scores")
            .select()
            .eq("situation_id", value: situationId.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let scores = try decoder.decode([ExperimentScore].self, from: resp.data)
        return scores.first
    }
}


