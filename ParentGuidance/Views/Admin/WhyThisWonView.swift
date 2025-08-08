import SwiftUI
import Supabase

struct WhyThisWonView: View {
    @State private var bullets: [String] = []
    @State private var highlights: [String] = []
    @State private var isLoading = false
    @EnvironmentObject var appCoordinator: AppCoordinator

    var body: some View {
        List {
            if !bullets.isEmpty {
                Section(header: Text("Judge Explanations")) {
                    ForEach(bullets, id: \.self) { b in Text("• \(b)") }
                }
            }
            if !highlights.isEmpty {
                Section(header: Text("Highlighted Context")) {
                    ForEach(highlights, id: \.self) { h in Text(h).italic() }
                }
            }
        }
        .task { await load() }
        .overlay(Group { if isLoading { ProgressView() } })
        .navigationTitle("Why this won")
    }

    private func load() async {
        guard let familyId = appCoordinator.children.first?.familyId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            // Fetch top recent explanation for family
            let resp = try await SupabaseManager.shared.client
                .from("experiment_scores")
                .select("explanations_json, created_at")
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
            if let json = try? JSONSerialization.jsonObject(with: resp.data) as? [[String: Any]],
               let first = json.first,
               let explanations = first["explanations_json"] as? [String: Any] {
                bullets = (explanations["bullets"] as? [String]) ?? []
                highlights = (explanations["highlights"] as? [String]) ?? []
            }
        } catch {
            bullets = []
            highlights = []
        }
    }
}


