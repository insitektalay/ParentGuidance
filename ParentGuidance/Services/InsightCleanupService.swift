import Foundation
import Supabase

@MainActor
class InsightCleanupService: ObservableObject {
    static let shared = InsightCleanupService()
    
    @Published var isRunning = false
    @Published var lastRunDate: Date?
    @Published var lastRunResult: CleanupResult?
    
    private let supabaseManager = SupabaseManager.shared
    
    struct CleanupResult: Codable {
        let dryRun: Bool
        let familyId: String?
        let contextualInsightsDeleted: Int
        let relevantInsightsDeleted: Int
        let insightBulletPointsDeleted: Int
        let totalDeleted: Int
        let timestamp: Date
        
        enum CodingKeys: String, CodingKey {
            case dryRun = "dry_run"
            case familyId = "family_id"
            case contextualInsightsDeleted = "contextual_insights_deleted"
            case relevantInsightsDeleted = "relevant_insights_deleted"
            case insightBulletPointsDeleted = "insight_bullet_points_deleted"
            case totalDeleted = "total_deleted"
            case timestamp
        }
    }
    
    private init() {
        // Load last run date from UserDefaults
        if let lastRun = UserDefaults.standard.object(forKey: "lastInsightCleanupDate") as? Date {
            lastRunDate = lastRun
        }
    }
    
    // MARK: - Public Methods
    
    /// Find orphaned insights without deleting them
    func findOrphanedInsights(familyId: UUID? = nil) async throws -> [(tableName: String, count: Int)] {
        let response: PostgrestResponse<Data>
        
        struct FindParams: Encodable {
            let p_family_id: String?
        }
        
        let params = FindParams(p_family_id: familyId?.uuidString)
        
        response = try await supabaseManager.client
            .rpc("find_orphaned_insights", params: params)
            .execute()
        
        struct OrphanedRecord: Decodable {
            let tableName: String
            let orphanedCount: Int
            
            enum CodingKeys: String, CodingKey {
                case tableName = "table_name"
                case orphanedCount = "orphaned_count"
            }
        }
        
        let records = try JSONDecoder().decode([OrphanedRecord].self, from: response.data)
        return records.map { ($0.tableName, $0.orphanedCount) }
    }
    
    /// Clean up orphaned insights
    func cleanupOrphanedInsights(familyId: UUID? = nil, dryRun: Bool = true) async throws -> CleanupResult {
        isRunning = true
        defer { isRunning = false }
        
        let response: PostgrestResponse<Data>
        
        struct CleanupParams: Encodable {
            let p_family_id: String?
            let p_dry_run: Bool
        }
        
        let params = CleanupParams(
            p_family_id: familyId?.uuidString,
            p_dry_run: dryRun
        )
        
        response = try await supabaseManager.client
            .rpc("cleanup_orphaned_insights", params: params)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(CleanupResult.self, from: response.data)
        
        if !dryRun {
            lastRunDate = Date()
            lastRunResult = result
            UserDefaults.standard.set(lastRunDate, forKey: "lastInsightCleanupDate")
        }
        
        return result
    }
    
    /// Run cleanup for all families (admin only)
    func runGlobalCleanup(dryRun: Bool = true) async throws -> CleanupResult {
        return try await cleanupOrphanedInsights(familyId: nil, dryRun: dryRun)
    }
    
    /// Schedule periodic cleanup (can be called on app launch)
    func schedulePeriodicCleanup() {
        Task {
            // Check if we should run cleanup (once per week)
            if let lastRun = lastRunDate {
                let daysSinceLastRun = Calendar.current.dateComponents([.day], from: lastRun, to: Date()).day ?? 0
                guard daysSinceLastRun >= 7 else { return }
            }
            
            // Run cleanup for current user's family
            guard let userId = supabaseManager.getCurrentUserId(),
                  let familyId = try? await fetchUserFamilyId(userId: userId) else { return }
            
            do {
                // First do a dry run to log what would be cleaned
                let dryRunResult = try await cleanupOrphanedInsights(familyId: familyId, dryRun: true)
                print("Orphaned insights found: \(dryRunResult.totalDeleted)")
                
                // If there are orphaned insights, clean them up
                if dryRunResult.totalDeleted > 0 {
                    let result = try await cleanupOrphanedInsights(familyId: familyId, dryRun: false)
                    print("Cleaned up \(result.totalDeleted) orphaned insights")
                }
            } catch {
                print("Failed to run periodic insight cleanup: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchUserFamilyId(userId: UUID) async throws -> UUID? {
        let response = try await supabaseManager.client
            .from("families")
            .select("id")
            .eq("created_by", value: userId.uuidString)
            .single()
            .execute()
        
        struct FamilyId: Decodable {
            let id: String
        }
        
        let family = try JSONDecoder().decode(FamilyId.self, from: response.data)
        return UUID(uuidString: family.id)
    }
}