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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        situationId: String,
        guidanceId: String,
        insightType: String,
        insightId: String,
        insightContent: String,
        relevanceScore: Float? = nil
    ) {
        self.id = UUID().uuidString
        self.situationId = situationId
        self.guidanceId = guidanceId
        self.insightType = insightType
        self.insightId = insightId
        self.insightContent = insightContent
        self.relevanceScore = relevanceScore
        self.createdAt = ISO8601DateFormatter().string(from: Date())
        self.updatedAt = ISO8601DateFormatter().string(from: Date())
    }
}

// MARK: - RelevantInsightsService

class RelevantInsightsService {
    static let shared = RelevantInsightsService()
    
    /// Feature flag to use Edge Function instead of direct OpenAI API
    private let useEdgeFunction = UserDefaults.standard.object(forKey: "relevant_insights_use_edge_function") as? Bool ?? true
    
    private init() {}
    
    // MARK: - Configuration Methods
    
    /// Enable or disable Edge Function usage for relevant insights selection
    static func setUseEdgeFunction(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "relevant_insights_use_edge_function")
        print("🔧 RelevantInsightsService Edge Function usage set to: \(enabled)")
    }
    
    /// Check if Edge Function is currently enabled
    static func isUsingEdgeFunction() -> Bool {
        return UserDefaults.standard.bool(forKey: "relevant_insights_use_edge_function")
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
        print("🎯 Selecting relevant insights for guidance: \(guidanceId)")
        
        // Step 1: Fetch all existing insights for the family (excluding current situation)
        let (contextualInsights, regulationInsights) = try await fetchAllFamilyInsights(
            familyId: familyId,
            excludingSituationId: situationId
        )
        
        print("📊 Found \(contextualInsights.count) contextual and \(regulationInsights.count) regulation insights")
        print("🔍 [DEBUG] Contextual insights details:")
        for insight in contextualInsights {
            print("   - [\(insight.category.displayName)] \(insight.content)")
        }
        print("🔍 [DEBUG] Regulation insights details:")
        for insight in regulationInsights {
            print("   - [\(insight.category.parentFriendlyName)] \(insight.content)")
        }
        
        // If no insights exist, return empty array
        guard !contextualInsights.isEmpty || !regulationInsights.isEmpty else {
            print("ℹ️ No existing insights found for family")
            return []
        }
        
        // Step 2: Format insights for LLM
        let insightsList = formatInsightsForLLM(
            contextual: contextualInsights,
            regulation: regulationInsights
        )
        
        print("📝 [DEBUG] Formatted insights list for LLM:")
        print("   Length: \(insightsList.count) characters")
        print("   Content preview: \(String(insightsList.prefix(500)))...")
        print("   Full content:")
        print("================== INSIGHTS LIST START ==================")
        print(insightsList)
        print("================== INSIGHTS LIST END ==================")
        
        print("📝 [DEBUG] Guidance text for LLM:")
        print("   Length: \(guidanceText.count) characters")
        print("   Content preview: \(String(guidanceText.prefix(500)))...")
        
        // Step 3: Call LLM to select relevant insights
        let selectedInsightTexts = try await callLLMForSelection(
            guidanceText: guidanceText,
            insightsList: insightsList,
            apiKey: apiKey
        )
        
        print("🤖 [DEBUG] LLM Response Analysis:")
        print("   Selected \(selectedInsightTexts.count) relevant insights")
        print("   Raw selected texts:")
        for (index, text) in selectedInsightTexts.enumerated() {
            print("     \(index + 1). \(text)")
        }
        
        // Step 4: Match selected texts back to original insights
        let relevantInsights = matchSelectedInsights(
            selectedTexts: selectedInsightTexts,
            contextualInsights: contextualInsights,
            regulationInsights: regulationInsights,
            situationId: situationId,
            guidanceId: guidanceId
        )
        
        // Step 5: Save to database
        if !relevantInsights.isEmpty {
            try await saveRelevantInsights(relevantInsights)
            print("✅ Saved \(relevantInsights.count) relevant insights to database")
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
        
        print("🚀 [DEBUG] Starting LLM call for insight selection")
        print("   useEdgeFunction: \(useEdgeFunction)")
        print("   API key: \(String(apiKey.prefix(10)))...")
        
        let result: [String]
        if useEdgeFunction {
            print("   Using EdgeFunction path")
            result = try await callEdgeFunctionForSelection(
                guidanceText: guidanceText,
                insightsList: insightsList,
                apiKey: apiKey
            )
        } else {
            print("   Using Direct API path")
            result = try await callDirectAPIForSelection(
                guidanceText: guidanceText,
                insightsList: insightsList,
                apiKey: apiKey
            )
        }
        
        print("✅ [DEBUG] LLM call completed, returned \(result.count) insights")
        return result
    }
    
    /// Call Edge Function for insight selection
    private func callEdgeFunctionForSelection(
        guidanceText: String,
        insightsList: String,
        apiKey: String
    ) async throws -> [String] {
        print("🚀 Using EdgeFunction for insight selection")
        
        let response = try await EdgeFunctionService.shared.selectWhichInsightsMatter(
            guidanceText: guidanceText,
            insightsList: insightsList,
            apiKey: apiKey
        )
        
        print("🔍 [DEBUG] EdgeFunction response received:")
        print("   Response length: \(response.count) characters")
        print("   Response preview: \(String(response.prefix(500)))")
        print("   Full response:")
        print("================== EDGE FUNCTION RESPONSE START ==================")
        print(response)
        print("================== EDGE FUNCTION RESPONSE END ==================")
        
        // Parse response - expecting a list of insight texts
        let parsedInsights = parseInsightSelectionResponse(response)
        print("📊 [DEBUG] After parsing EdgeFunction response:")
        print("   Parsed \(parsedInsights.count) insights")
        for (index, insight) in parsedInsights.enumerated() {
            print("     \(index + 1). '\(insight)'")
        }
        
        return parsedInsights
    }
    
    /// Call Direct API for insight selection (fallback)
    private func callDirectAPIForSelection(
        guidanceText: String,
        insightsList: String,
        apiKey: String
    ) async throws -> [String] {
        print("🔗 Using Direct API for insight selection")
        
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
            print("❌ [DEBUG] Direct API: No content in response")
            print("   Response structure: \(promptResponse)")
            throw NSError(domain: "RelevantInsightsError", code: 500, userInfo: [NSLocalizedDescriptionKey: "No content in response"])
        }
        
        print("🔍 [DEBUG] Direct API response received:")
        print("   Response text length: \(firstContent.text.count) characters")
        print("   Response text preview: \(String(firstContent.text.prefix(500)))")
        print("   Full response text:")
        print("================== DIRECT API RESPONSE START ==================")
        print(firstContent.text)
        print("================== DIRECT API RESPONSE END ==================")
        
        let parsedInsights = parseInsightSelectionResponse(firstContent.text)
        print("📊 [DEBUG] After parsing Direct API response:")
        print("   Parsed \(parsedInsights.count) insights")
        for (index, insight) in parsedInsights.enumerated() {
            print("     \(index + 1). '\(insight)'")
        }
        
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
            let categoryName = if let subcategory = insight.subcategory {
                "\(insight.category.displayName) - \(subcategory.displayName)"
            } else {
                insight.category.displayName
            }
            let prefix = "[\(categoryName)] "
            insights.append(prefix + insight.content)
        }
        
        // Add regulation insights
        for insight in regulation {
            let prefix = "[\(insight.category.parentFriendlyName)] "
            insights.append(prefix + insight.content)
        }
        
        print("🔧 [DEBUG] Formatted \(insights.count) insights for LLM:")
        for (index, insight) in insights.enumerated() {
            print("     \(index + 1). \(insight)")
        }
        
        return insights.joined(separator: "\n")
    }
    
    /// Parse LLM response to extract selected insight texts
    private func parseInsightSelectionResponse(_ response: String) -> [String] {
        print("🔧 [DEBUG] Parsing insight selection response")
        print("   Raw response length: \(response.count)")
        print("   Raw response: '\(response)'")
        
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
            print("   Strategy 1 (bracket pattern): Found \(insights.count) insights")
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
                print("   Strategy 2 (numbered list): Found \(insights.count) insights")
            }
        }
        
        // Strategy 3: Fallback to simple newline splitting (original approach)
        if insights.isEmpty {
            let components = response.components(separatedBy: .newlines)
            let trimmed = components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            insights = trimmed.filter { !$0.isEmpty && $0.contains("[") && $0.contains("]") }
            print("   Strategy 3 (newline split): Found \(insights.count) insights")
        }
        
        // Strategy 4: Handle comma-separated responses
        if insights.isEmpty && response.contains(",") {
            let components = response.components(separatedBy: ",")
            let trimmed = components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            insights = trimmed.filter { !$0.isEmpty && $0.contains("[") && $0.contains("]") }
            print("   Strategy 4 (comma split): Found \(insights.count) insights")
        }
        
        print("   Final parsing result: \(insights.count) insights")
        for (index, insight) in insights.enumerated() {
            print("     \(index + 1). '\(insight)'")
        }
        
        return insights
    }
    
    /// Match selected texts back to original insights
    private func matchSelectedInsights(
        selectedTexts: [String],
        contextualInsights: [ContextualInsight],
        regulationInsights: [ChildRegulationInsight],
        situationId: String,
        guidanceId: String
    ) -> [RelevantInsight] {
        print("🔍 [DEBUG] Matching selected texts to original insights")
        print("   Selected texts count: \(selectedTexts.count)")
        print("   Available contextual insights: \(contextualInsights.count)")
        print("   Available regulation insights: \(regulationInsights.count)")
        
        var relevantInsights: [RelevantInsight] = []
        
        for (index, selectedText) in selectedTexts.enumerated() {
            print("   Processing selected text \(index + 1): '\(selectedText)'")
            var foundMatch = false
            
            // Try to match with contextual insights
            for insight in contextualInsights {
                // Handle both with and without subcategories
                let categoryName = if let subcategory = insight.subcategory {
                    "\(insight.category.displayName) - \(subcategory.displayName)"
                } else {
                    insight.category.displayName
                }
                let expectedPrefix = "[\(categoryName)] "
                print("     Checking contextual prefix: '\(expectedPrefix)'")
                if selectedText.hasPrefix(expectedPrefix) {
                    let content = String(selectedText.dropFirst(expectedPrefix.count))
                    print("     Extracted content: '\(content)'")
                    print("     Original content: '\(insight.content)'")
                    
                    // Try exact match first
                    if content == insight.content {
                        print("     ✅ EXACT MATCH FOUND for contextual insight!")
                        relevantInsights.append(RelevantInsight(
                            situationId: situationId,
                            guidanceId: guidanceId,
                            insightType: "contextual",
                            insightId: insight.id,
                            insightContent: insight.content
                        ))
                        foundMatch = true
                        break
                    }
                    // Try fuzzy match for minor differences
                    else if isFuzzyMatch(selected: content, original: insight.content) {
                        print("     ✅ FUZZY MATCH FOUND for contextual insight!")
                        relevantInsights.append(RelevantInsight(
                            situationId: situationId,
                            guidanceId: guidanceId,
                            insightType: "contextual",
                            insightId: insight.id,
                            insightContent: insight.content
                        ))
                        foundMatch = true
                        break
                    } else {
                        print("     ❌ Content mismatch (similarity: \(String(format: "%.2f", calculateSimilarity(selected: content, original: insight.content))))")
                    }
                } else {
                    print("     ❌ Prefix mismatch")
                }
            }
            
            if !foundMatch {
                // Try to match with regulation insights
                for insight in regulationInsights {
                    let expectedPrefix = "[\(insight.category.parentFriendlyName)] "
                    print("     Checking regulation prefix: '\(expectedPrefix)'")
                    if selectedText.hasPrefix(expectedPrefix) {
                        let content = String(selectedText.dropFirst(expectedPrefix.count))
                        print("     Extracted content: '\(content)'")
                        print("     Original content: '\(insight.content)'")
                        
                        // Try exact match first
                        if content == insight.content {
                            print("     ✅ EXACT MATCH FOUND for regulation insight!")
                            relevantInsights.append(RelevantInsight(
                                situationId: situationId,
                                guidanceId: guidanceId,
                                insightType: "regulation",
                                insightId: insight.id.uuidString,
                                insightContent: insight.content
                            ))
                            foundMatch = true
                            break
                        }
                        // Try fuzzy match for minor differences
                        else if isFuzzyMatch(selected: content, original: insight.content) {
                            print("     ✅ FUZZY MATCH FOUND for regulation insight!")
                            relevantInsights.append(RelevantInsight(
                                situationId: situationId,
                                guidanceId: guidanceId,
                                insightType: "regulation",
                                insightId: insight.id.uuidString,
                                insightContent: insight.content
                            ))
                            foundMatch = true
                            break
                        } else {
                            print("     ❌ Content mismatch (similarity: \(String(format: "%.2f", calculateSimilarity(selected: content, original: insight.content))))")
                        }
                    } else {
                        print("     ❌ Prefix mismatch")
                    }
                }
            }
            
            if !foundMatch {
                print("     ❌ NO MATCH FOUND for selected text: '\(selectedText)'")
            }
        }
        
        print("✅ [DEBUG] Matching completed: \(relevantInsights.count) insights matched")
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
}