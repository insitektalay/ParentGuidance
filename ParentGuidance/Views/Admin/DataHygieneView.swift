import SwiftUI

struct DataHygieneView: View {
    @State private var isRunning = false
    @State private var dryRunCounts: [(String, Int)] = []
    @EnvironmentObject var appCoordinator: AppCoordinator

    var body: some View {
        Form {
            Section(header: Text("Dry-run")) {
                Button(isRunning ? "Running…" : "Find Orphans") {
                    Task { await runDryRun() }
                }.disabled(isRunning)
                ForEach(dryRunCounts, id: \.0) { item in
                    HStack { Text(item.0); Spacer(); Text("\(item.1)") }
                }
            }
            Section(header: Text("Commit")) {
                Button("Cleanup Orphans") {
                    Task { await runCommit() }
                }.disabled(isRunning || dryRunCounts.isEmpty)
            }
        }
        .navigationTitle("Insight Hygiene")
    }

    private func runDryRun() async {
        guard let familyIdString = appCoordinator.children.first?.familyId, let uuid = UUID(uuidString: familyIdString) else { return }
        isRunning = true
        defer { isRunning = false }
        do {
            let results = try await InsightCleanupService.shared.findOrphanedInsights(familyId: uuid)
            dryRunCounts = results
        } catch { dryRunCounts = [] }
    }

    private func runCommit() async {
        guard let familyIdString = appCoordinator.children.first?.familyId, let uuid = UUID(uuidString: familyIdString) else { return }
        isRunning = true
        defer { isRunning = false }
        do {
            _ = try await InsightCleanupService.shared.cleanupOrphanedInsights(familyId: uuid, dryRun: false)
            dryRunCounts = []
        } catch {}
    }
}


