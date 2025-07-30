//
//  ContextualInsightService.swift
//  ParentGuidance
//
//  Created by alex kerss on 17/07/2025.
//

import Foundation
import Supabase

class ContextualInsightService {
    static let shared = ContextualInsightService()
    
    /// Feature flag to use Edge Function instead of direct OpenAI API
    private let useEdgeFunction = UserDefaults.standard.bool(forKey: "context_use_edge_function")
    
    private init() {}
    
    // MARK: - Configuration Methods
    
    /// Enable or disable Edge Function usage for contextual insight extraction
    static func setUseEdgeFunction(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "context_use_edge_function")
        print("🔧 ContextualInsightService Edge Function usage set to: \(enabled)")
    }
    
    /// Check if Edge Function is currently enabled
    static func isUsingEdgeFunction() -> Bool {
        return UserDefaults.standard.bool(forKey: "context_use_edge_function")
    }
    
    // MARK: - Context Extraction
    
    func extractChildRegulationInsights(
        situationText: String,
        apiKey: String,
        familyId: String,
        childId: String? = nil,
        situationId: String
    ) async throws -> [ChildRegulationInsight] {
        print("🧠 Starting child regulation insights extraction for situation: \(situationId)")
        print("📝 Situation text: \(situationText.prefix(100))...")
        
        // Choose implementation based on feature flag
        let content: String
        if useEdgeFunction {
            print("🚀 [ContextualInsightService] Using EdgeFunction for child regulation insights")
            content = try await extractChildRegulationInsightsViaEdgeFunction(
                situationText: situationText,
                apiKey: apiKey
            )
        } else {
            print("🔗 [ContextualInsightService] Using Direct API for child regulation insights")
            content = try await extractChildRegulationInsightsViaDirectAPI(
                situationText: situationText,
                apiKey: apiKey
            )
        }
        
        // Parse the response using existing logic
        let insights = try parseRegulationInsightsResponse(
            content: content,
            familyId: familyId,
            childId: childId,
            situationId: situationId
        )
        
        print("✅ Parsed \(insights.count) child regulation insights")
        return insights
    }
    
    /// Extract coping strategies from situation text
    func extractCopingStrategies(
        situationText: String,
        apiKey: String,
        familyId: String,
        childId: String? = nil,
        situationId: String
    ) async throws -> [ChildRegulationInsight] {
        print("🧠 Starting coping strategies extraction for situation: \(situationId)")
        print("📝 Situation text: \(situationText.prefix(100))...")
        
        // Choose implementation based on feature flag
        let content: String
        if useEdgeFunction {
            print("🚀 [ContextualInsightService] Using EdgeFunction for coping strategies")
            content = try await extractCopingStrategiesViaEdgeFunction(
                situationText: situationText,
                apiKey: apiKey
            )
        } else {
            print("🔗 [ContextualInsightService] Using Direct API for coping strategies")
            content = try await extractCopingStrategiesViaDirectAPI(
                situationText: situationText,
                apiKey: apiKey
            )
        }
        
        // Parse the response into ChildRegulationInsight objects
        let insights = try parseCopingStrategiesResponse(
            content: content,
            familyId: familyId,
            childId: childId,
            situationId: situationId
        )
        
        print("✅ Parsed \(insights.count) coping strategies")
        return insights
    }
    
    /// Extract coping strategies using Edge Function approach
    private func extractCopingStrategiesViaEdgeFunction(
        situationText: String,
        apiKey: String
    ) async throws -> String {
        print("🔄 Using Edge Function for coping strategies extraction")
        
        do {
            let response = try await EdgeFunctionService.shared.extractCopingStrategies(
                situationText: situationText,
                apiKey: apiKey
            )
            
            print("✅ Coping strategies extracted via Edge Function")
            return response
            
        } catch {
            print("❌ Edge Function coping strategies extraction failed: \(error)")
            throw ContextualInsightError.apiError(0)
        }
    }
    
    /// Extract coping strategies using legacy direct API approach
    private func extractCopingStrategiesViaDirectAPI(
        situationText: String,
        apiKey: String
    ) async throws -> String {
        print("🔄 Using direct API for coping strategies extraction (legacy)")
        
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "prompt": [
                "id": "pmpt_coping_strat",
                "version": "1",
                "variables": [
                    "longtext": situationText
                ]
            ]
        ]
        
        print("📡 Making coping strategies API request...")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response for coping strategies")
            throw ContextualInsightError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Coping strategies HTTP error: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(responseString)")
            }
            throw ContextualInsightError.apiError(httpResponse.statusCode)
        }
        
        print("✅ Coping strategies HTTP 200 response received")
        
        do {
            // Parse using the same PromptResponse structure
            let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
            
            guard let firstOutput = promptResponse.output.first,
                  let firstContent = firstOutput.content.first else {
                print("❌ No content in coping strategies response")
                throw ContextualInsightError.noContent
            }
            
            let content = firstContent.text
            print("📝 Coping strategies content received: \(content.prefix(200))...")
            
            return content
            
        } catch {
            print("❌ Error parsing coping strategies response: \(error)")
            throw ContextualInsightError.parsingError(error)
        }
    }
    
    /// Extract child regulation insights using Edge Function approach
    private func extractChildRegulationInsightsViaEdgeFunction(
        situationText: String,
        apiKey: String
    ) async throws -> String {
        print("🔄 Using Edge Function for child regulation insights extraction")
        
        do {
            let response = try await EdgeFunctionService.shared.extractContext(
                situationText: situationText,
                extractionType: "regulation",
                apiKey: apiKey
            )
            
            print("✅ Child regulation insights extracted via Edge Function")
            return response
            
        } catch {
            print("❌ Edge Function regulation insights extraction failed: \(error)")
            throw ContextualInsightError.apiError(0)
        }
    }
    
    /// Extract child regulation insights using legacy direct API approach
    private func extractChildRegulationInsightsViaDirectAPI(
        situationText: String,
        apiKey: String
    ) async throws -> String {
        print("🔄 Using direct API for child regulation insights extraction (legacy)")
        
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "prompt": [
                "id": "pmpt_6877c15da6388196a389c79feeefd4e30cccdbe5ba3909fb",
                "version": "5",
                "variables": [
                    "long_prompt": situationText
                ]
            ]
        ]
        
        print("📡 Making child regulation insights API request...")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response for child regulation insights")
            throw ContextualInsightError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Child regulation insights HTTP error: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(responseString)")
            }
            throw ContextualInsightError.apiError(httpResponse.statusCode)
        }
        
        print("✅ Child regulation insights HTTP 200 response received")
        
        do {
            // Parse using the same PromptResponse structure
            let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
            
            guard let firstOutput = promptResponse.output.first,
                  let firstContent = firstOutput.content.first else {
                print("❌ No content in child regulation insights response")
                throw ContextualInsightError.noContent
            }
            
            let content = firstContent.text
            print("📝 Child regulation insights content received: \(content.prefix(200))...")
            
            return content
            
        } catch {
            print("❌ Error parsing child regulation insights response: \(error)")
            throw ContextualInsightError.parsingError(error)
        }
    }
    
    func extractContextFromSituation(
        situationText: String,
        apiKey: String,
        familyId: String,
        childId: String? = nil,
        situationId: String
    ) async throws -> [ContextualInsight] {
        print("🔍 Starting context extraction for situation: \(situationId)")
        print("📝 Situation text: \(situationText.prefix(100))...")
        
        // Choose implementation based on feature flag
        let content: String
        if useEdgeFunction {
            print("🚀 [ContextualInsightService] Using EdgeFunction for context extraction")
            content = try await extractContextFromSituationViaEdgeFunction(
                situationText: situationText,
                apiKey: apiKey
            )
        } else {
            print("🔗 [ContextualInsightService] Using Direct API for context extraction")
            content = try await extractContextFromSituationViaDirectAPI(
                situationText: situationText,
                apiKey: apiKey
            )
        }
        
        // Parse the 14-section response into contextual insights using existing logic
        let insights = parseContextResponse(
            content: content,
            familyId: familyId,
            childId: childId,
            situationId: situationId
        )
        
        print("✅ Parsed \(insights.count) contextual insights")
        return insights
    }
    
    /// Extract context using Edge Function approach
    private func extractContextFromSituationViaEdgeFunction(
        situationText: String,
        apiKey: String
    ) async throws -> String {
        print("🔄 Using Edge Function for context extraction")
        
        do {
            let response = try await EdgeFunctionService.shared.extractContext(
                situationText: situationText,
                extractionType: "general",
                apiKey: apiKey
            )
            
            print("✅ Context extracted via Edge Function")
            return response
            
        } catch {
            print("❌ Edge Function context extraction failed: \(error)")
            throw ContextualInsightError.apiError(0)
        }
    }
    
    /// Extract context using legacy direct API approach
    private func extractContextFromSituationViaDirectAPI(
        situationText: String,
        apiKey: String
    ) async throws -> String {
        print("🔄 Using direct API for context extraction (legacy)")
        
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "prompt": [
                "id": "pmpt_68778827e310819792876a9f5a844c050059609da32e4637",
                "version": "4",
                "variables": [
                    "long_prompt": situationText
                ]
            ]
        ]
        
        print("📡 Making context extraction API request...")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response for context extraction")
            throw ContextualInsightError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Context extraction HTTP error: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(responseString)")
            }
            throw ContextualInsightError.apiError(httpResponse.statusCode)
        }
        
        print("✅ Context extraction HTTP 200 response received")
        
        do {
            // Parse using the same PromptResponse structure as NewSituationView
            let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
            
            guard let firstOutput = promptResponse.output.first,
                  let firstContent = firstOutput.content.first else {
                print("❌ No content in context extraction response")
                throw ContextualInsightError.noContent
            }
            
            let content = firstContent.text
            print("📝 Context extraction content received: \(content.prefix(200))...")
            
            return content
            
        } catch {
            print("❌ Error parsing context extraction response: \(error)")
            throw ContextualInsightError.parsingError(error)
        }
    }
    
    // MARK: - Response Parsing
    
    private func parseCopingStrategiesResponse(
        content: String,
        familyId: String,
        childId: String?,
        situationId: String
    ) throws -> [ChildRegulationInsight] {
        print("🧠 Parsing coping strategies response...")
        
        // The coping strategies prompt returns a simple list
        // Split by newlines and filter out empty lines
        let strategies = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { !$0.hasPrefix("•") && !$0.hasPrefix("-") && !$0.hasPrefix("*") ? true : !String($0.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { strategy in
                // Clean up bullet points and numbered lists if they exist
                var cleaned = strategy
                if cleaned.hasPrefix("• ") || cleaned.hasPrefix("- ") || cleaned.hasPrefix("* ") {
                    cleaned = String(cleaned.dropFirst(2))
                }
                // Handle numbered lists (1. 2. 3. etc.)
                if let range = cleaned.range(of: "^\\d+\\.\\s*", options: .regularExpression) {
                    cleaned = String(cleaned[range.upperBound...])
                }
                return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
        
        var insights: [ChildRegulationInsight] = []
        let responseId = UUID().uuidString
        
        for strategy in strategies {
            let insight = ChildRegulationInsight(
                familyId: familyId,
                childId: childId,
                situationId: situationId,
                category: .copingStrategies,
                content: strategy,
                insightResponseId: responseId
            )
            insights.append(insight)
        }
        
        print("🧠 Parsed \(insights.count) coping strategies from response")
        return insights
    }
    
    private func parseRegulationInsightsResponse(
        content: String,
        familyId: String,
        childId: String?,
        situationId: String
    ) throws -> [ChildRegulationInsight] {
        print("🧠 Parsing regulation insights JSON response...")
        
        // Try to parse as JSON first
        guard let jsonData = content.data(using: .utf8) else {
            print("❌ Could not convert response to data")
            throw ContextualInsightError.parsingError(NSError(domain: "JSONParsingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not convert response to data"]))
        }
        
        do {
            let decoder = JSONDecoder()
            let regulationResponse = try decoder.decode(ChildRegulationInsightsResponse.self, from: jsonData)
            
            // Convert to individual bullet points using the model's extension
            let insights = regulationResponse.toBulletPoints(
                familyId: familyId,
                childId: childId,
                situationId: situationId,
                responseId: UUID().uuidString
            )
            
            // Filter out "No strong patterns found" responses
            let filteredInsights = insights.filter { !$0.isNoPatternFound }
            
            print("✅ Parsed \(insights.count) total insights, \(filteredInsights.count) after filtering")
            return filteredInsights
            
        } catch {
            print("❌ JSON parsing failed, trying fallback parsing: \(error)")
            
            // Fallback: try to parse as plain text with JSON-like structure
            return parseFallbackRegulationResponse(
                content: content,
                familyId: familyId,
                childId: childId,
                situationId: situationId
            )
        }
    }
    
    private func parseFallbackRegulationResponse(
        content: String,
        familyId: String,
        childId: String?,
        situationId: String
    ) -> [ChildRegulationInsight] {
        print("🔄 Using fallback parsing for regulation insights...")
        
        var insights: [ChildRegulationInsight] = []
        let responseId = UUID().uuidString
        
        // Try to extract sections by category names
        let categories: [(name: String, category: RegulationCategory)] = [
            ("Core", .core),
            ("ADHD", .adhd),
            ("Mild Autism", .mildAutism)
        ]
        
        for (categoryName, category) in categories {
            if let sectionContent = extractRegulationSection(from: content, categoryName: categoryName) {
                let bulletPoints = extractBulletPoints(from: sectionContent)
                
                for bulletPoint in bulletPoints {
                    if !bulletPoint.contains("No strong patterns found") {
                        let insight = ChildRegulationInsight(
                            familyId: familyId,
                            childId: childId,
                            situationId: situationId,
                            category: category,
                            content: bulletPoint,
                            insightResponseId: responseId
                        )
                        insights.append(insight)
                    }
                }
            }
        }
        
        print("✅ Fallback parsing created \(insights.count) insights")
        return insights
    }
    
    private func extractRegulationSection(from content: String, categoryName: String) -> String? {
        // Look for patterns like "Core": [...] or "Core" : [...]
        let patterns = [
            "\"\(categoryName)\"\\s*:\\s*\\[([^\\]]+)\\]",
            "\(categoryName)\\s*:\\s*\\[([^\\]]+)\\]",
            "\"\(categoryName)\"\\s*:\\s*([^,}]+)"
        ]
        
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(content.startIndex..., in: content)
            
            if let match = regex?.firstMatch(in: content, options: [], range: range) {
                if let swiftRange = Range(match.range(at: 1), in: content) {
                    let extracted = String(content[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    print("✅ Extracted \(categoryName) section: \(extracted.prefix(50))...")
                    return extracted
                }
            }
        }
        
        print("⚠️ No section found for: \(categoryName)")
        return nil
    }
    
    private func extractBulletPoints(from content: String) -> [String] {
        // Remove quotes and brackets, then split by common separators
        let cleaned = content
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
        
        // Split by commas, newlines, and bullets
        let separators = [",", "\n", "•", "- "]
        var bulletPoints = [cleaned]
        
        for separator in separators {
            var newPoints: [String] = []
            for point in bulletPoints {
                let parts = point.components(separatedBy: separator)
                newPoints.append(contentsOf: parts)
            }
            bulletPoints = newPoints
        }
        
        // Clean and filter
        return bulletPoints
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 5 }
    }
    
    private func parseContextResponse(
        content: String,
        familyId: String,
        childId: String?,
        situationId: String
    ) -> [ContextualInsight] {
        print("🔍 Parsing context response into structured insights...")
        
        var insights: [ContextualInsight] = []
        
        // Define the 14 sections to parse
        let sections = [
            "family context",
            "proven regulation tools – physical/sensory",
            "proven regulation tools – environmental",
            "proven regulation tools – routine/predictable",
            "proven regulation tools – key success patterns",
            "proven regulation tools – timing notes",
            "medical / health",
            "educational / academic",
            "peer / social",
            "behavioral patterns",
            "daily life / practical",
            "temporal / timing",
            "environmental & tech triggers",
            "parenting approaches",
            "sibling dynamics"
        ]
        
        for sectionKey in sections {
            if let extractedContent = extractSectionContent(from: content, sectionKey: sectionKey) {
                // Skip "none found" responses
                if extractedContent.lowercased().contains("none found") {
                    continue
                }
                
                // Split multiple insights if separated by newlines or bullets
                let individualInsights = splitInsights(extractedContent)
                
                for insightText in individualInsights {
                    if let insight = createInsight(
                        text: insightText,
                        sectionKey: sectionKey,
                        familyId: familyId,
                        childId: childId,
                        situationId: situationId
                    ) {
                        insights.append(insight)
                    }
                }
            }
        }
        
        print("✅ Created \(insights.count) contextual insights from response")
        return insights
    }
    
    private func extractSectionContent(from content: String, sectionKey: String) -> String? {
        // Pattern to match "section_name: \n<content>" until next section or end
        let pattern = "\(NSRegularExpression.escapedPattern(for: sectionKey)):\\s*\\n([\\s\\S]*?)(?=\\n\\s*[a-zA-Z].*?:|$)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let range = NSRange(content.startIndex..., in: content)
        
        if let match = regex?.firstMatch(in: content, options: [], range: range) {
            if let swiftRange = Range(match.range(at: 1), in: content) {
                let extracted = String(content[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                print("✅ Extracted \(sectionKey): \(extracted.prefix(50))...")
                return extracted
            }
        }
        
        print("⚠️ No content found for: \(sectionKey)")
        return nil
    }
    
    private func splitInsights(_ content: String) -> [String] {
        // Split by common separators: newlines, bullets, numbers
        let separators = ["\n", "•", "- ", "1.", "2.", "3.", "4.", "5."]
        var insights = [content]
        
        for separator in separators {
            var newInsights: [String] = []
            for insight in insights {
                let parts = insight.components(separatedBy: separator)
                newInsights.append(contentsOf: parts)
            }
            insights = newInsights
        }
        
        // Filter out empty or very short insights
        return insights
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 10 }
    }
    
    private func createInsight(
        text: String,
        sectionKey: String,
        familyId: String,
        childId: String?,
        situationId: String
    ) -> ContextualInsight? {
        guard let category = ContextCategory.from(apiResponseKey: sectionKey) else {
            print("❌ Unable to map section key to category: \(sectionKey)")
            return nil
        }
        
        let subcategory = ContextSubcategory.from(apiResponseKey: sectionKey)
        
        let insight = ContextualInsight(
            familyId: familyId,
            childId: childId,
            category: category,
            subcategory: subcategory,
            content: text,
            sourceSituationId: situationId
        )
        
        print("✅ Created insight: \(category.displayName) - \(text.prefix(30))...")
        return insight
    }
    
    // MARK: - Database Operations
    
    /// Fetch existing coping strategies for a family
    func fetchCopingStrategies(familyId: String) async throws -> [ChildRegulationInsight] {
        print("📋 Fetching existing coping strategies for family: \(familyId)")
        
        do {
            let insights: [ChildRegulationInsight] = try await SupabaseManager.shared.client
                .from("insight_bullet_points")
                .select("*")
                .eq("family_id", value: familyId)
                .eq("category", value: RegulationCategory.copingStrategies.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            // Filter out "No strong patterns found" entries
            let validInsights = insights.filter { !$0.isNoPatternFound }
            
            print("✅ Found \(validInsights.count) existing coping strategies")
            return validInsights
        } catch {
            print("❌ Error fetching coping strategies: \(error)")
            throw error
        }
    }
    
    func saveChildRegulationInsights(_ insights: [ChildRegulationInsight]) async throws {
        print("💾 Saving \(insights.count) child regulation insights to database...")
        
        guard !insights.isEmpty else {
            print("⚠️ No regulation insights to save")
            return
        }
        
        do {
            try await SupabaseManager.shared.client
                .from("insight_bullet_points")
                .insert(insights)
                .execute()
            
            print("✅ Successfully saved \(insights.count) child regulation insights")
        } catch {
            print("❌ Error saving child regulation insights: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    func getChildRegulationInsights(
        familyId: String,
        childId: String? = nil,
        category: RegulationCategory? = nil,
        situationId: String? = nil
    ) async throws -> [ChildRegulationInsight] {
        print("📋 Getting child regulation insights for family: \(familyId)")
        
        do {
            var query = SupabaseManager.shared.client
                .from("insight_bullet_points")
                .select("*")
                .eq("family_id", value: familyId)
            
            if let childId = childId {
                query = query.eq("child_id", value: childId)
            }
            
            if let category = category {
                query = query.eq("category", value: category.rawValue)
            }
            
            if let situationId = situationId {
                query = query.eq("situation_id", value: situationId)
            }
            
            let response: [ChildRegulationInsight] = try await query
                .order("created_at", ascending: false)
                .execute().value
            
            print("✅ Found \(response.count) child regulation insights")
            return response
        } catch {
            print("❌ Error getting child regulation insights: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    func getRegulationInsightCounts(familyId: String, childId: String? = nil) async throws -> [RegulationCategory: Int] {
        print("📊 Getting regulation insight counts for family: \(familyId)")
        
        do {
            let allInsights = try await getChildRegulationInsights(familyId: familyId, childId: childId)
            var counts: [RegulationCategory: Int] = [:]
            
            for insight in allInsights {
                counts[insight.category, default: 0] += 1
            }
            
            print("✅ Calculated regulation insight counts for \(counts.count) categories")
            return counts
        } catch {
            print("❌ Error getting regulation insight counts: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    func deleteChildRegulationInsight(id: String) async throws {
        print("🗑️ Deleting child regulation insight: \(id)")
        
        do {
            print("🔍 Fetching insight details for ID: \(id)")
            // First, check if this is a coping strategy - if so, archive it
            let insight: ChildRegulationInsight = try await SupabaseManager.shared.client
                .from("insight_bullet_points")
                .select("*")
                .eq("id", value: id)
                .single()
                .execute()
                .value
            
            print("✅ Found insight with category: \(insight.category.rawValue)")
            
            // If it's a coping strategy, save to deleted archive first
            if insight.category == .copingStrategies {
                print("🎯 This is a coping strategy - archiving before deletion")
                let deletedStrategy = DeletedCopingStrategy(from: insight)
                try await saveDeletedCopingStrategy(deletedStrategy)
                print("📦 Archived coping strategy before deletion: \(id)")
            } else {
                print("ℹ️ Not a coping strategy (\(insight.category.rawValue)) - skipping archive")
            }
            
            print("🗑️ Now deleting from main table...")
            // Then delete from main table
            try await SupabaseManager.shared.client
                .from("insight_bullet_points")
                .delete()
                .eq("id", value: id)
                .execute()
            
            print("✅ Successfully deleted child regulation insight: \(id)")
        } catch {
            print("❌ Error deleting child regulation insight: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    // MARK: - Deleted Coping Strategies Management
    
    /// Save a deleted coping strategy to the archive table
    private func saveDeletedCopingStrategy(_ deletedStrategy: DeletedCopingStrategy) async throws {
        print("📦 Saving deleted coping strategy to archive: \(deletedStrategy.id)")
        
        try await SupabaseManager.shared.client
            .from("deleted_coping_strategies")
            .insert(deletedStrategy)
            .execute()
        
        print("✅ Successfully archived deleted coping strategy")
    }
    
    /// Get all deleted coping strategies for a family
    func getDeletedCopingStrategies(familyId: String) async throws -> [DeletedCopingStrategy] {
        print("📋 Fetching deleted coping strategies for family: \(familyId)")
        print("🔍 Searching for family_id: '\(familyId)'")
        
        do {
            // First, let's see what's actually in the table
            let allRecords: [DeletedCopingStrategy] = try await SupabaseManager.shared.client
                .from("deleted_coping_strategies")
                .select("*")
                .execute()
                .value
            
            print("📊 Total records in deleted_coping_strategies table: \(allRecords.count)")
            for (index, record) in allRecords.enumerated() {
                print("   Record \(index + 1): family_id='\(record.familyId)', content='\(record.content.prefix(50))...', deleted_at=\(record.deletedAt)")
            }
            
            // Now try the specific family query (use lowercase for consistency)
            let deletedStrategies: [DeletedCopingStrategy] = try await SupabaseManager.shared.client
                .from("deleted_coping_strategies")
                .select("*")
                .eq("family_id", value: familyId.lowercased())
                .order("deleted_at", ascending: false)
                .execute()
                .value
            
            print("✅ Found \(deletedStrategies.count) deleted coping strategies for family: \(familyId)")
            return deletedStrategies
        } catch {
            print("❌ Error fetching deleted coping strategies: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Restore a deleted coping strategy back to the main table
    func restoreDeletedCopingStrategy(id: String) async throws {
        print("♻️ Restoring deleted coping strategy: \(id)")
        
        do {
            // Get the deleted strategy
            let deletedStrategy: DeletedCopingStrategy = try await SupabaseManager.shared.client
                .from("deleted_coping_strategies")
                .select("*")
                .eq("id", value: id)
                .single()
                .execute()
                .value
            
            // Convert back to ChildRegulationInsight and save
            let restoredInsight = deletedStrategy.toChildRegulationInsight()
            try await saveChildRegulationInsights([restoredInsight])
            
            // Remove from deleted table
            try await SupabaseManager.shared.client
                .from("deleted_coping_strategies")
                .delete()
                .eq("id", value: id)
                .execute()
            
            print("✅ Successfully restored coping strategy: \(id)")
        } catch {
            print("❌ Error restoring deleted coping strategy: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Permanently delete a coping strategy from the deleted archive
    func permanentlyDeleteCopingStrategy(id: String) async throws {
        print("🗑️ Permanently deleting coping strategy from archive: \(id)")
        
        do {
            try await SupabaseManager.shared.client
                .from("deleted_coping_strategies")
                .delete()
                .eq("id", value: id)
                .execute()
            
            print("✅ Successfully permanently deleted coping strategy: \(id)")
        } catch {
            print("❌ Error permanently deleting coping strategy: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    func saveContextInsights(_ insights: [ContextualInsight]) async throws {
        print("💾 Saving \(insights.count) contextual insights to database...")
        
        guard !insights.isEmpty else {
            print("⚠️ No insights to save")
            return
        }
        
        do {
            try await SupabaseManager.shared.client
                .from("contextual_insights")
                .insert(insights)
                .execute()
            
            print("✅ Successfully saved \(insights.count) contextual insights")
        } catch {
            print("❌ Error saving contextual insights: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    func getInsightsByCategory(
        familyId: String,
        category: ContextCategory,
        subcategory: ContextSubcategory? = nil
    ) async throws -> [ContextualInsight] {
        print("📋 Getting insights for category: \(category.displayName)")
        
        do {
            let response: [ContextualInsight] = if let subcategory = subcategory {
                try await SupabaseManager.shared.client
                    .from("contextual_insights")
                    .select("*")
                    .eq("family_id", value: familyId)
                    .eq("category", value: category.rawValue)
                    .eq("subcategory", value: subcategory.rawValue)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            } else {
                try await SupabaseManager.shared.client
                    .from("contextual_insights")
                    .select("*")
                    .eq("family_id", value: familyId)
                    .eq("category", value: category.rawValue)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }
            
            print("✅ Found \(response.count) insights for category: \(category.displayName)")
            return response
        } catch {
            print("❌ Error getting insights by category: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    func getAllInsights(familyId: String) async throws -> [ContextualInsight] {
        print("📚 Getting all insights for family: \(familyId)")
        
        do {
            let response: [ContextualInsight] = try await SupabaseManager.shared.client
                .from("contextual_insights")
                .select("*")
                .eq("family_id", value: familyId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("✅ Found \(response.count) total insights for family")
            return response
        } catch {
            print("❌ Error getting all insights: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    func deleteInsight(id: String) async throws {
        print("🗑️ Deleting insight: \(id)")
        
        do {
            try await SupabaseManager.shared.client
                .from("contextual_insights")
                .delete()
                .eq("id", value: id)
                .execute()
            
            print("✅ Successfully deleted insight: \(id)")
        } catch {
            print("❌ Error deleting insight: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    // MARK: - Utility Methods
    
    func getInsightCounts(familyId: String) async throws -> [ContextCategory: Int] {
        print("📊 Getting insight counts for family: \(familyId)")
        
        do {
            let allInsights = try await getAllInsights(familyId: familyId)
            var counts: [ContextCategory: Int] = [:]
            
            for insight in allInsights {
                counts[insight.category, default: 0] += 1
            }
            
            print("✅ Calculated insight counts for \(counts.count) categories")
            return counts
        } catch {
            print("❌ Error getting insight counts: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    func getInsightsByChild(familyId: String, childId: String) async throws -> [ContextualInsight] {
        print("👶 Getting insights for child: \(childId)")
        
        do {
            let response: [ContextualInsight] = try await SupabaseManager.shared.client
                .from("contextual_insights")
                .select("*")
                .eq("family_id", value: familyId)
                .eq("child_id", value: childId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("✅ Found \(response.count) insights for child")
            return response
        } catch {
            print("❌ Error getting insights by child: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
}

// MARK: - Error Handling

enum ContextualInsightError: Error {
    case invalidResponse
    case noContent
    case parsingError(Error)
    case databaseError(Error)
    case apiError(Int)
    
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from context extraction API"
        case .noContent:
            return "No content received from context extraction API"
        case .parsingError(let error):
            return "Error parsing context response: \(error.localizedDescription)"
        case .databaseError(let error):
            return "Database error: \(error.localizedDescription)"
        case .apiError(let statusCode):
            return "API error with status code: \(statusCode)"
        }
    }
}