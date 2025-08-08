//
//  RelevantInsightsService.swift
//  ParentGuidance
//
//  Created by alex kerss on 01/08/2025.
//

import Foundation
import Supabase

// MARK: - RelevantInsight Model

struct RelevantInsight: Codable {
    let id: String
    let situationId: String
    let guidanceId: String
    let insightType: String // 'contextual' or 'regulation'
    let insightId: String
    let insightContent: String
    let relevanceScore: Float?
    let familyId: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case situationId = "situation_id"
        case guidanceId = "guidance_id"
        case insightType = "insight_type"
        case insightId = "insight_id"
        case insightContent = "insight_content"
        case relevanceScore = "relevance_score"
        case familyId = "family_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        situationId: String,
        guidanceId: String,
        insightType: String,
        insightId: String,
        insightContent: String,
        relevanceScore: Float? = nil,
        familyId: String? = nil
    ) {
        self.id = UUID().uuidString
        self.situationId = situationId
        self.guidanceId = guidanceId
        self.insightType = insightType
        self.insightId = insightId
        self.insightContent = insightContent
        self.relevanceScore = relevanceScore
        self.familyId = familyId
        self.createdAt = ISO8601DateFormatter().string(from: Date())
        self.updatedAt = ISO8601DateFormatter().string(from: Date())
    }
}

// MARK: - RelevantInsightsService

class RelevantInsightsService {
    static let shared = RelevantInsightsService()
    
    /// Feature flag to use Edge Function instead of direct OpenAI API
    private let useEdgeFunction = UserDefaults.standard.object(forKey: "relevant_insights_use_edge_function") as? Bool ?? true
    
    /// Ultra-minimal debug mode - only shows critical RLS issues
    private let ultraDebugMode = true // Set to false to disable all insights debugging
    
    private init() {}
    
    // MARK: - Configuration Methods
    
    /// Enable or disable Edge Function usage for relevant insights selection
    static func setUseEdgeFunction(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "relevant_insights_use_edge_function")
        print("🔧 RelevantInsightsService Edge Function usage set to: \(enabled)")
    }
    
    /// Check if Edge Function is currently enabled
    static func isUsingEdgeFunction() -> Bool {
        return UserDefaults.standard.object(forKey: "relevant_insights_use_edge_function") as? Bool ?? true
    }
    
    // MARK: - Main Selection Method
    
    /// Select relevant insights for a given guidance text
    func selectRelevantInsights(
        guidanceText: String,
        situationId: String,
        guidanceId: String,
        familyId: String,
        apiKey: String
    ) async throws -> [RelevantInsight] {
        if ultraDebugMode { print("🔍 [INSIGHTS] SAVE: \(guidanceId)") }
        
        // Step 1: Fetch all existing insights for the family (excluding current situation)
        let (contextualInsights, regulationInsights) = try await fetchAllFamilyInsights(
            familyId: familyId,
            excludingSituationId: situationId
        )
        
        // If no insights exist, return empty array
        guard !contextualInsights.isEmpty || !regulationInsights.isEmpty else {
            if ultraDebugMode { print("❌ No existing insights found for family") }
            return []
        }
        
        // Step 2: Format insights for LLM
        let insightsList = formatInsightsForLLM(
            contextual: contextualInsights,
            regulation: regulationInsights
        )
        
        // Step 3: Call LLM to select relevant insights
        let selectedInsightTexts = try await callLLMForSelection(
            guidanceText: guidanceText,
            insightsList: insightsList,
            apiKey: apiKey
        )
        
        // Step 4: Match selected texts back to original insights
        let relevantInsights = matchSelectedInsights(
            selectedTexts: selectedInsightTexts,
            contextualInsights: contextualInsights,
            regulationInsights: regulationInsights,
            situationId: situationId,
            guidanceId: guidanceId,
            familyId: familyId
        )
        
        // Step 5: Save to database
        if !relevantInsights.isEmpty {
            try await saveRelevantInsights(relevantInsights)
            if ultraDebugMode { print("✅ [INSIGHTS] SAVED: \(guidanceId) → \(relevantInsights.count)") }
        } else {
            if ultraDebugMode { print("❌ [INSIGHTS] NONE: \(guidanceId) → 0") }
        }
        
        return relevantInsights
    }
    
    /// Select relevant insights for a historical situation (respects historical context)
    func selectRelevantInsightsForHistoricalSituation(
        guidanceText: String,
        situationId: String,
        guidanceId: String,
        familyId: String,
        situationDate: String,
        apiKey: String
    ) async throws -> [RelevantInsight] {
        // Historical insights selection for Library view
        
        // Step 1: Fetch insights that existed before or on the situation date
        let (contextualInsights, regulationInsights) = try await fetchAllFamilyInsightsBeforeDate(
            familyId: familyId,
            excludingSituationId: situationId,
            beforeDate: situationDate
        )
        
        // If no insights existed at that time, return empty array
        guard !contextualInsights.isEmpty || !regulationInsights.isEmpty else {
            return []
        }
        
        // Step 2: Format insights for LLM
        let insightsList = formatInsightsForLLM(
            contextual: contextualInsights,
            regulation: regulationInsights
        )
        
        
        // Step 3: Call LLM to select relevant insights
        let selectedInsightTexts = try await callLLMForSelection(
            guidanceText: guidanceText,
            insightsList: insightsList,
            apiKey: apiKey
        )
        
        print("🤖 [HISTORICAL] LLM selected \(selectedInsightTexts.count) insights from historical context")
        
        // Step 4: Match selected texts back to original insights
        let relevantInsights = matchSelectedInsights(
            selectedTexts: selectedInsightTexts,
            contextualInsights: contextualInsights,
            regulationInsights: regulationInsights,
            situationId: situationId,
            guidanceId: guidanceId,
            familyId: familyId
        )
        
        // Step 5: Save to database
        if !relevantInsights.isEmpty {
            try await saveRelevantInsights(relevantInsights)
            print("✅ Saved \(relevantInsights.count) historical relevant insights to database")
        }
        
        return relevantInsights
    }
    
    // MARK: - Database Operations
    
    /// Fetch all insights for a family, excluding a specific situation
    private func fetchAllFamilyInsights(
        familyId: String,
        excludingSituationId: String
    ) async throws -> (contextual: [ContextualInsight], regulation: [ChildRegulationInsight]) {
        
        // Fetch contextual insights
        let contextualInsights: [ContextualInsight] = try await SupabaseManager.shared.client
            .from("contextual_insights")
            .select("*")
            .eq("family_id", value: familyId)
            .neq("source_situation_id", value: excludingSituationId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        // Fetch regulation insights
        let regulationInsights: [ChildRegulationInsight] = try await SupabaseManager.shared.client
            .from("insight_bullet_points")
            .select("*")
            .eq("family_id", value: familyId)
            .neq("situation_id", value: excludingSituationId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return (contextualInsights, regulationInsights)
    }
    
    /// Fetch all insights for a family that existed before a specific date
    private func fetchAllFamilyInsightsBeforeDate(
        familyId: String,
        excludingSituationId: String,
        beforeDate: String
    ) async throws -> (contextual: [ContextualInsight], regulation: [ChildRegulationInsight]) {
        
        // Fetch insights that existed before the situation date
        
        // Fetch contextual insights created before the situation date
        let contextualInsights: [ContextualInsight] = try await SupabaseManager.shared.client
            .from("contextual_insights")
            .select("*")
            .eq("family_id", value: familyId)
            .neq("source_situation_id", value: excludingSituationId)
            .lte("created_at", value: beforeDate)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        // Fetch regulation insights created before the situation date
        let regulationInsights: [ChildRegulationInsight] = try await SupabaseManager.shared.client
            .from("insight_bullet_points")
            .select("*")
            .eq("family_id", value: familyId)
            .neq("situation_id", value: excludingSituationId)
            .lte("created_at", value: beforeDate)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        // Return insights that existed before the situation date
        
        return (contextualInsights, regulationInsights)
    }
    
    /// Save relevant insights to database
    private func saveRelevantInsights(_ insights: [RelevantInsight]) async throws {
        try await SupabaseManager.shared.client
            .from("relevant_insights")
            .insert(insights)
            .execute()
    }
    
    /// Get relevant insights for a specific guidance
    func getRelevantInsights(guidanceId: String) async throws -> [RelevantInsight] {
        print("📋 Fetching relevant insights for guidance: \(guidanceId)")
        
        let insights: [RelevantInsight] = try await SupabaseManager.shared.client
            .from("relevant_insights")
            .select("*")
            .eq("guidance_id", value: guidanceId)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        print("✅ Found \(insights.count) relevant insights")
        return insights
    }
    
    // MARK: - LLM Integration
    
    /// Call LLM to select relevant insights
    private func callLLMForSelection(
        guidanceText: String,
        insightsList: String,
        apiKey: String
    ) async throws -> [String] {
        
        let result: [String]
        if useEdgeFunction {
            result = try await callEdgeFunctionForSelection(
                guidanceText: guidanceText,
                insightsList: insightsList,
                apiKey: apiKey
            )
        } else {
            result = try await callDirectAPIForSelection(
                guidanceText: guidanceText,
                insightsList: insightsList,
                apiKey: apiKey
            )
        }
        
        return result
    }
    
    /// Call Edge Function for insight selection
    private func callEdgeFunctionForSelection(
        guidanceText: String,
        insightsList: String,
        apiKey: String
    ) async throws -> [String] {
        let response = try await EdgeFunctionService.shared.selectWhichInsightsMatter(
            guidanceText: guidanceText,
            insightsList: insightsList,
            apiKey: apiKey
        )
        
        // Parse response - expecting a list of insight texts
        let parsedInsights = parseInsightSelectionResponse(response)
        
        return parsedInsights
    }
    
    /// Call Direct API for insight selection (fallback)
    private func callDirectAPIForSelection(
        guidanceText: String,
        insightsList: String,
        apiKey: String
    ) async throws -> [String] {
        
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "prompt": [
                "id": "pmpt_which_matter",
                "version": "1",
                "variables": [
                    "GuidanceText": guidanceText,
                    "InsightList": insightsList
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "RelevantInsightsError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to select insights"])
        }
        
        let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
        
        guard let firstOutput = promptResponse.output.first,
              let firstContent = firstOutput.content.first else {
            throw NSError(domain: "RelevantInsightsError", code: 500, userInfo: [NSLocalizedDescriptionKey: "No content in response"])
        }
        
        let parsedInsights = parseInsightSelectionResponse(firstContent.text)
        
        return parsedInsights
    }
    
    // MARK: - Helper Methods
    
    /// Format insights for LLM consumption
    private func formatInsightsForLLM(
        contextual: [ContextualInsight],
        regulation: [ChildRegulationInsight]
    ) -> String {
        var insights: [String] = []
        
        // Add contextual insights (include subcategory if present)
        for insight in contextual {
            let categoryName = insight.category.displayName
            let prefix = "[\(categoryName)] "
            insights.append(prefix + insight.content)
        }
        
        // Add regulation insights
        for insight in regulation {
            let prefix = "[\(insight.category.parentFriendlyName)] "
            insights.append(prefix + insight.content)
        }
        
        
        return insights.joined(separator: "\n")
    }
    
    /// Parse LLM response to extract selected insight texts
    private func parseInsightSelectionResponse(_ response: String) -> [String] {
        
        // Try multiple parsing strategies to handle various LLM response formats
        var insights: [String] = []
        
        // Strategy 1: Look for bracket-delimited insights [Category] content
        let bracketPattern = "\\[([^\\]]+)\\]\\s*(.+)"
        if let regex = try? NSRegularExpression(pattern: bracketPattern, options: []) {
            let matches = regex.matches(in: response, options: [], range: NSRange(location: 0, length: response.count))
            for match in matches {
                if match.numberOfRanges >= 3 {
                    let categoryRange = Range(match.range(at: 1), in: response)!
                    let contentRange = Range(match.range(at: 2), in: response)!
                    let category = String(response[categoryRange])
                    let content = String(response[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let fullInsight = "[\(category)] \(content)"
                    insights.append(fullInsight)
                }
            }
        }
        
        // Strategy 2: If no bracket format found, try numbered list parsing
        if insights.isEmpty {
            let numberedPattern = "^\\s*\\d+\\.\\s*\\[([^\\]]+)\\]\\s*(.+)$"
            if let regex = try? NSRegularExpression(pattern: numberedPattern, options: [.anchorsMatchLines]) {
                let matches = regex.matches(in: response, options: [], range: NSRange(location: 0, length: response.count))
                for match in matches {
                    if match.numberOfRanges >= 3 {
                        let categoryRange = Range(match.range(at: 1), in: response)!
                        let contentRange = Range(match.range(at: 2), in: response)!
                        let category = String(response[categoryRange])
                        let content = String(response[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                        let fullInsight = "[\(category)] \(content)"
                        insights.append(fullInsight)
                    }
                }
            }
        }
        
        // Strategy 3: Fallback to simple newline splitting (original approach)
        if insights.isEmpty {
            let components = response.components(separatedBy: .newlines)
            let trimmed = components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            insights = trimmed.filter { !$0.isEmpty && $0.contains("[") && $0.contains("]") }
        }
        
        // Strategy 4: Handle comma-separated responses
        if insights.isEmpty && response.contains(",") {
            let components = response.components(separatedBy: ",")
            let trimmed = components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            insights = trimmed.filter { !$0.isEmpty && $0.contains("[") && $0.contains("]") }
        }
        
        
        return insights
    }
    
    /// Match selected texts back to original insights
    private func matchSelectedInsights(
        selectedTexts: [String],
        contextualInsights: [ContextualInsight],
        regulationInsights: [ChildRegulationInsight],
        situationId: String,
        guidanceId: String,
        familyId: String
    ) -> [RelevantInsight] {
        
        var relevantInsights: [RelevantInsight] = []
        
        for selectedText in selectedTexts {
            var foundMatch = false
            
            // Try to match with contextual insights
            for insight in contextualInsights {
                let categoryName = insight.category.displayName
                let expectedPrefix = "[\(categoryName)] "
                if selectedText.hasPrefix(expectedPrefix) {
                    let content = String(selectedText.dropFirst(expectedPrefix.count))
                    
                    // Try exact match first
                    if content == insight.content {
                        relevantInsights.append(RelevantInsight(
                            situationId: situationId,
                            guidanceId: guidanceId,
                            insightType: "contextual",
                            insightId: insight.id,
                            insightContent: insight.content,
                            relevanceScore: nil,
                            familyId: familyId.lowercased()
                        ))
                        foundMatch = true
                        break
                    }
                    // Try fuzzy match for minor differences
                    else if isFuzzyMatch(selected: content, original: insight.content) {
                        relevantInsights.append(RelevantInsight(
                            situationId: situationId,
                            guidanceId: guidanceId,
                            insightType: "contextual",
                            insightId: insight.id,
                            insightContent: insight.content,
                            relevanceScore: nil,
                            familyId: familyId.lowercased()
                        ))
                        foundMatch = true
                        break
                    }
                }
            }
            
            if !foundMatch {
                // Try to match with regulation insights
                for insight in regulationInsights {
                    let expectedPrefix = "[\(insight.category.parentFriendlyName)] "
                    if selectedText.hasPrefix(expectedPrefix) {
                        let content = String(selectedText.dropFirst(expectedPrefix.count))
                        
                        // Try exact match first
                        if content == insight.content {
                            relevantInsights.append(RelevantInsight(
                                situationId: situationId,
                                guidanceId: guidanceId,
                                insightType: "regulation",
                                insightId: insight.id.uuidString,
                                insightContent: insight.content,
                                relevanceScore: nil,
                                familyId: familyId.lowercased()
                            ))
                            foundMatch = true
                            break
                        }
                        // Try fuzzy match for minor differences
                        else if isFuzzyMatch(selected: content, original: insight.content) {
                            relevantInsights.append(RelevantInsight(
                                situationId: situationId,
                                guidanceId: guidanceId,
                                insightType: "regulation",
                                insightId: insight.id.uuidString,
                                insightContent: insight.content,
                                relevanceScore: nil,
                                familyId: familyId.lowercased()
                            ))
                            foundMatch = true
                            break
                        }
                    }
                }
            }
        }
        return relevantInsights
    }
    
    // MARK: - Fuzzy Matching Helpers
    
    /// Check if two strings are similar enough to be considered a match
    private func isFuzzyMatch(selected: String, original: String) -> Bool {
        let similarity = calculateSimilarity(selected: selected, original: original)
        return similarity >= 0.85 // 85% similarity threshold
    }
    
    /// Calculate similarity between two strings using a simple metric
    private func calculateSimilarity(selected: String, original: String) -> Double {
        // Normalize strings for comparison
        let normalizedSelected = normalizeString(selected)
        let normalizedOriginal = normalizeString(original)
        
        // Use Levenshtein distance for similarity
        let distance = levenshteinDistance(normalizedSelected, normalizedOriginal)
        let maxLength = max(normalizedSelected.count, normalizedOriginal.count)
        
        if maxLength == 0 { return 1.0 }
        
        let similarity = 1.0 - (Double(distance) / Double(maxLength))
        return max(0.0, similarity)
    }
    
    /// Normalize string for comparison by removing extra whitespace and punctuation differences
    private func normalizeString(_ string: String) -> String {
        return string
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[.!?]+$", with: "", options: .regularExpression) // Remove trailing punctuation
    }
    
    /// Calculate Levenshtein distance between two strings
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let s1Count = s1Array.count
        let s2Count = s2Array.count
        
        guard s1Count > 0 else { return s2Count }
        guard s2Count > 0 else { return s1Count }
        
        var matrix = Array(repeating: Array(repeating: 0, count: s2Count + 1), count: s1Count + 1)
        
        // Initialize first row and column
        for i in 0...s1Count { matrix[i][0] = i }
        for j in 0...s2Count { matrix[0][j] = j }
        
        // Fill the matrix
        for i in 1...s1Count {
            for j in 1...s2Count {
                let cost = s1Array[i-1] == s2Array[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }
        
        return matrix[s1Count][s2Count]
    }
    
    // MARK: - Time Machine Support
    
    /// Select relevant insights for a historical situation during regeneration
    func selectRelevantInsightsForHistoricalSituation(
        situationId: UUID,
        priorToDate: Date,
        regenRunId: UUID,
        experimentRunId: UUID? = nil
    ) async throws {
        // Get situation details
        let response = try await SupabaseManager.shared.client
            .from("situations")
            .select("*, guidance!inner(*)")
            .eq("id", value: situationId.uuidString)
            .single()
            .execute()
        
        struct SituationWithGuidance: Decodable {
            let id: String
            let family_id: String
            let created_at: String
            let guidance: [GuidanceData]
            
            struct GuidanceData: Decodable {
                let id: String
                let content: String
            }
        }
        
        let decoder = JSONDecoder()
        let situationData = try decoder.decode(SituationWithGuidance.self, from: response.data)
        
        guard let guidanceData = situationData.guidance.first else {
            print("⚠️ No guidance found for situation during regeneration")
            return
        }
        
        // Select relevant insights using the existing method
        _ = try await selectRelevantInsightsForHistoricalSituation(
            guidanceText: guidanceData.content,
            situationId: situationId.uuidString,
            guidanceId: guidanceData.id,
            familyId: situationData.family_id,
            situationDate: situationData.created_at,
            apiKey: UserDefaults.standard.string(forKey: "openAIApiKey") ?? ""
        )
        
        // Update the relevant insights with regen_run_id
        try await SupabaseManager.shared.client
            .from("relevant_insights")
            .update([
                "regen_run_id": regenRunId.uuidString,
                "experiment_run_id": experimentRunId?.uuidString ?? NSNull()
            ])
            .eq("situation_id", value: situationId.uuidString)
            .eq("guidance_id", value: guidanceData.id)
            .execute()
    }
}