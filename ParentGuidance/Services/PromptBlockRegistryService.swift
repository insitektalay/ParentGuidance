import Foundation
import Supabase

@MainActor
final class PromptBlockRegistryService: ObservableObject {
    static let shared = PromptBlockRegistryService()
    private init() {}

    private let client = SupabaseManager.shared.client

    func listBlocks(enabledOnly: Bool = false) async throws -> [PromptBlock] {
        var query = client.from("prompt_blocks").select()
        if enabledOnly { query = query.eq("enabled", value: true) }
        let response = try await query.order("updated_at", ascending: false).execute()
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([PromptBlock].self, from: response.data)
    }

    func upsertBlock(_ block: PromptBlock) async throws {
        try await client.from("prompt_blocks").upsert(block).execute()
    }

    func disableBlock(id: UUID) async throws {
        try await client.from("prompt_blocks").update(["enabled": false]).eq("id", value: id.uuidString).execute()
    }
}


