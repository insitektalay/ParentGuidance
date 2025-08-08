import SwiftUI

struct LeaderboardView: View {
    @State private var entries: [ExperimentLeaderboardService.Entry] = []
    @State private var isLoading = false
    @EnvironmentObject var appCoordinator: AppCoordinator

    var body: some View {
        List(entries) { e in
            HStack {
                VStack(alignment: .leading) {
                    Text(e.name).font(.headline)
                    if let completed = e.completedAt {
                        Text(completed.formatted()).font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(String(format: "%.3f", e.averageComposite)).bold()
                    Text("n=\(e.situationsProcessed)").font(.caption)
                }
            }
        }
        .task { await load() }
        .overlay(Group { if isLoading { ProgressView() } })
        .navigationTitle("Leaderboard")
    }

    private func load() async {
        guard let familyIdString = appCoordinator.children.first?.familyId,
              let familyUUID = UUID(uuidString: familyIdString) else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            entries = try await ExperimentLeaderboardService.shared.getLeaderboard(familyId: familyUUID)
        } catch {
            entries = []
        }
    }
}


