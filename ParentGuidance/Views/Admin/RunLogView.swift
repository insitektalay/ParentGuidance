import SwiftUI
import Supabase

struct RunLogView: View {
    let regenRunId: UUID
    @State private var logs: [LogEntry] = []
    @State private var isLoading = false

    struct LogEntry: Identifiable, Decodable {
        let id = UUID()
        let ts: String
        let level: String
        let message: String
    }

    var body: some View {
        List(logs) { entry in
            HStack(alignment: .top, spacing: 8) {
                Text(entry.level.uppercased())
                    .font(.caption2)
                    .foregroundColor(color(for: entry.level))
                    .frame(width: 60, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.ts).font(.caption).foregroundColor(.secondary)
                    Text(entry.message).font(.body)
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .overlay(Group { if isLoading { ProgressView() } })
        .navigationTitle("Run Logs")
    }

    private func color(for level: String) -> Color {
        switch level.lowercased() {
        case "error": return .red
        case "warn": return .orange
        default: return .blue
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let resp = try await SupabaseManager.shared.client
                .from("regen_run_logs")
                .select("ts, level, message")
                .eq("regen_run_id", value: regenRunId.uuidString)
                .order("ts", ascending: false)
                .limit(200)
                .execute()
            let decoder = JSONDecoder()
            logs = try decoder.decode([LogEntry].self, from: resp.data)
        } catch {
            logs = []
        }
    }
}


