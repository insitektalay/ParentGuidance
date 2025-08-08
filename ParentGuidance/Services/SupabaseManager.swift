import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://xxrbavrptjexshgkpzon.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4cmJhdnJwdGpleHNoZ2twem9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAzNDcyMzAsImV4cCI6MjA2NTkyMzIzMH0.rMaFYwRKaF22SyuP4ZRtsshUngebtQb_hl8zYduV65E"
        )
    }
    
    // MARK: - Authentication Management
    
    /// Ensure user session is valid and refresh if needed
    func ensureValidSession() async throws {
        do {
            try await client.auth.refreshSession()
        } catch {
            print("⚠️ [SupabaseManager] Session refresh failed: \(error)")
            throw error
        }
    }
    
    /// Validate that we have a current authenticated user
    func validateAuthContext() async throws {
        guard let currentUser = client.auth.currentUser else {
            throw NSError(domain: "AuthError", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        // Session is non-optional in this version, just check we have a user
        print("✅ [SupabaseManager] Valid auth context: user=\(currentUser.id)")
    }
    
    /// Get the current user ID
    func getCurrentUserId() -> UUID? {
        guard let currentUser = client.auth.currentUser else {
            return nil
        }
        return UUID(uuidString: currentUser.id.uuidString)
    }
    
    /// Test auth context using diagnostic RPC
    func testAuthContext() async throws -> [String: Any] {
        try await ensureValidSession()
        
        // Call the diagnostic RPC and return empty dict for now - 
        // actual implementation will depend on database RPC being available
        do {
            _ = try await client
                .rpc("rpc_whoami")
                .execute()
            print("🔍 [SupabaseManager] Auth context test passed")
            return ["status": "ok"]
        } catch {
            print("⚠️ [SupabaseManager] Auth context test failed: \(error)")
            return ["status": "failed", "error": error.localizedDescription]
        }
    }
}


