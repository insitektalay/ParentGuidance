import Foundation
import Supabase

@MainActor
class ManualRegenerationService: ObservableObject {
    static let shared = ManualRegenerationService()
    
    @Published var situationsNeedingRegeneration: Set<String> = []
    @Published var regeneratingSituations: Set<String> = []
    @Published var regenerationErrors: [String: String] = [:]
    @Published var isCheckingStatus = false
    
    private let supabaseManager = SupabaseManager.shared
    private let conversationService = ConversationService.shared
    private let contextualInsightService = ContextualInsightService.shared
    private let relevantInsightsService = RelevantInsightsService.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Check which situations in the family need regeneration (have no guidance)
    func checkRegenerationStatus(familyId: UUID) async throws {
        isCheckingStatus = true
        defer { isCheckingStatus = false }
        
        // Query situations without guidance
        let _ = """
            SELECT s.id
            FROM situations s
            LEFT JOIN guidance g ON s.id = g.situation_id
            WHERE s.family_id = ?
            AND g.id IS NULL
            ORDER BY s.created_at ASC
        """
        
        let response = try await supabaseManager.client
            .from("situations")
            .select("id, created_at, guidance(id)")
            .eq("family_id", value: familyId.uuidString)
            .order("created_at", ascending: true)
            .execute()
        
        struct SituationWithGuidance: Decodable {
            let id: String
            let createdAt: String
            let guidance: [GuidanceCheck]
            
            struct GuidanceCheck: Decodable {
                let id: String
            }
            
            enum CodingKeys: String, CodingKey {
                case id
                case createdAt = "created_at"
                case guidance
            }
        }
        
        let decoder = JSONDecoder()
        let situations = try decoder.decode([SituationWithGuidance].self, from: response.data)
        
        // Update the set of situations needing regeneration
        situationsNeedingRegeneration = Set(
            situations
                .filter { $0.guidance.isEmpty }
                .map { $0.id }
        )
        
        // Update ordered list for chronological enforcement
        let needingRegen = situations
            .filter { $0.guidance.isEmpty }
            .map { (id: $0.id, createdAt: $0.createdAt) }
        updateOrderedList(from: needingRegen)
        
        print("Found \(situationsNeedingRegeneration.count) situations needing regeneration")
    }
    
    /// Check if a specific situation needs regeneration
    func needsRegeneration(situationId: String) -> Bool {
        return situationsNeedingRegeneration.contains(situationId)
    }
    
    /// Check if a specific situation is currently being regenerated
    func isRegenerating(situationId: String) -> Bool {
        return regeneratingSituations.contains(situationId)
    }
    
    /// Get error message for a specific situation
    func getError(situationId: String) -> String? {
        return regenerationErrors[situationId]
    }
    
    /// Regenerate guidance for a specific situation
    func regenerateGuidance(
        for situation: Situation,
        regenRunId: UUID? = nil,
        experimentRunId: UUID? = nil,
        resolvedPolicy: ResolvedPolicy? = nil,
        overrideChronology: Bool = false
    ) async throws {
        guard let situationId = UUID(uuidString: situation.id) else {
            throw RegenerationError.invalidSituationId
        }
        
        // Check if already regenerating
        guard !isRegenerating(situationId: situation.id) else {
            throw RegenerationError.alreadyRegenerating
        }
        
        // Check chronological order constraint
        if !overrideChronology {
            if let earliestId = getEarliestSituationNeedingRegeneration() {
                guard earliestId == situation.id else {
                    throw RegenerationError.chronologicalOrderViolation(
                        message: "Please regenerate situations in chronological order. Start with the earliest situation first."
                    )
                }
            }
        }
        
        // Mark as regenerating
        regeneratingSituations.insert(situation.id)
        regenerationErrors.removeValue(forKey: situation.id)
        
        do {
            // Step 1: Generate guidance
            print("Regenerating guidance for situation: \(situation.title)")
            let guidance = try await conversationService.generateGuidance(
                situationId: situationId,
                situationText: situation.description,
                childName: "your child",
                regenRunId: regenRunId,
                experimentRunId: experimentRunId
            )
            
            print("✓ Guidance regenerated successfully")
            
            // Step 2: Extract contextual insights (if enabled)
            let contextEnabled = resolvedPolicy?.promptBlocks.contextExtraction?.enabled ?? UserDefaults.standard.bool(forKey: "aiProcessingContextExtraction")
            if contextEnabled {
                print("Extracting contextual insights...")
                try await contextualInsightService.extractContextualInsights(
                    situationId: situationId,
                    situationText: situation.description,
                    regenRunId: regenRunId,
                    experimentRunId: experimentRunId
                )
                print("✓ Contextual insights extracted")
            }
            
            // Step 3: Extract regulation insights (if enabled)
            let regulationEnabled = UserDefaults.standard.bool(forKey: "aiProcessingRegulationInsights")
            if regulationEnabled {
                print("Extracting regulation insights...")
                try await contextualInsightService.extractRegulationInsights(
                    situationId: situationId,
                    situationText: situation.description,
                    childName: "your child",
                    regenRunId: regenRunId,
                    experimentRunId: experimentRunId
                )
                print("✓ Regulation insights extracted")
            }
            
            // Step 4: Match relevant insights (if enabled)
            let relevantEnabled = resolvedPolicy?.promptBlocks.relevantInsights?.enabled ?? UserDefaults.standard.bool(forKey: "aiProcessingRelevantInsights")
            if relevantEnabled {
                print("Matching relevant insights...")
                try await relevantInsightsService.selectRelevantInsightsForHistoricalSituation(
                    situationId: situationId,
                    priorToDate: Date(),
                    regenRunId: regenRunId ?? UUID()
                )
                print("✓ Relevant insights matched")
            }
            
            // Remove from needs regeneration set
            situationsNeedingRegeneration.remove(situation.id)
            
        } catch {
            // Record error
            regenerationErrors[situation.id] = error.localizedDescription
            print("❌ Regeneration failed: \(error.localizedDescription)")
            // Remove from regenerating set
            regeneratingSituations.remove(situation.id)
            throw error
        }
        
        // Remove from regenerating set on success
        regeneratingSituations.remove(situation.id)
    }
    
    /// Get the earliest situation that needs regeneration (for chronological order enforcement)
    func getEarliestSituationNeedingRegeneration() -> String? {
        return situationsNeedingRegenerationOrdered.first
    }
    
    /// Ordered list of situations needing regeneration (chronological order)
    @Published var situationsNeedingRegenerationOrdered: [String] = []
    
    /// Update the ordered list when checking regeneration status
    private func updateOrderedList(from situations: [(id: String, createdAt: String)]) {
        // Sort by created_at date
        let sorted = situations.sorted { first, second in
            // Parse ISO8601 dates and compare
            let formatter = ISO8601DateFormatter()
            let date1 = formatter.date(from: first.createdAt) ?? Date.distantPast
            let date2 = formatter.date(from: second.createdAt) ?? Date.distantPast
            return date1 < date2
        }
        
        situationsNeedingRegenerationOrdered = sorted
            .filter { situationsNeedingRegeneration.contains($0.id) }
            .map { $0.id }
    }
    
    /// Clear all tracking data (useful when leaving the view)
    func clearTrackingData() {
        situationsNeedingRegeneration.removeAll()
        regeneratingSituations.removeAll()
        regenerationErrors.removeAll()
    }
}

// MARK: - Error Types

enum RegenerationError: LocalizedError {
    case invalidSituationId
    case alreadyRegenerating
    case chronologicalOrderViolation(message: String)
    case guidanceGenerationFailed(String)
    case insightExtractionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidSituationId:
            return "Invalid situation ID"
        case .alreadyRegenerating:
            return "This situation is already being regenerated"
        case .chronologicalOrderViolation(let message):
            return message
        case .guidanceGenerationFailed(let error):
            return "Failed to generate guidance: \(error)"
        case .insightExtractionFailed(let error):
            return "Failed to extract insights: \(error)"
        }
    }
}