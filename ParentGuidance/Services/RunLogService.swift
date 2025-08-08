import Foundation
import Supabase

@MainActor
final class RunLogService {
    static let shared = RunLogService()
    private init() {}

    enum LogLevel: String { case info, warn, error }

    func log(
        regenRunId: UUID?,
        experimentRunId: UUID? = nil,
        level: LogLevel = .info,
        message: String
    ) async {
        guard let regenRunId = regenRunId else { return }
        struct LogInsert: Encodable {
            let regenRunId: String
            let ts: String
            let level: String
            let message: String
            let experimentRunId: String?
            enum CodingKeys: String, CodingKey {
                case regenRunId = "regen_run_id"
                case ts
                case level
                case message
                case experimentRunId = "experiment_run_id"
            }
        }
        let payload = LogInsert(
            regenRunId: regenRunId.uuidString,
            ts: ISO8601DateFormatter().string(from: Date()),
            level: level.rawValue,
            message: message,
            experimentRunId: experimentRunId?.uuidString
        )
        do {
            try await SupabaseManager.shared.client
                .from("regen_run_logs")
                .insert(payload)
                .execute()
        } catch {
            // Best-effort logging; ignore failures
            print("[RunLogService] Failed to log: \(error)")
        }
    }
}


