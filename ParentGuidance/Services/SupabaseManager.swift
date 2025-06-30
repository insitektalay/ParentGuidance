import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://xxrbavrptjexshgkpzon.supabase.com")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4cmJhdnJwdGpleHNoZ2twem9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAzNDcyMzAsImV4cCI6MjA2NTkyMzIzMH0.rMaFYwRKaF22SyuP4ZRtsshUngebtQb_hl8zYduV65E"
        )
    }
}


