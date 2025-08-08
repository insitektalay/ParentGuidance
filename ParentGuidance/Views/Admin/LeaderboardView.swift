import SwiftUI

struct LeaderboardView: View {
    @State private var entries: [ExperimentScore] = []
    @State private var isLoading = false

    var body: some View {
        List(entries, id: \.id) { score in
            HStack {
                Text(score.situationId.uuidString.prefix(8))
                Spacer()
                Text(String(format: "%.3f", score.compositeScore))
            }
        }
        .overlay(Group { if isLoading { ProgressView() } })
        .navigationTitle("Leaderboard")
    }
}


