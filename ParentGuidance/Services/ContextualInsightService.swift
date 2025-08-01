//
//  ContextualInsightService.swift
//  ParentGuidance
//
//  Created by alex kerss on 17/07/2025.
//

import Foundation
import Supabase

// MARK: - Deduplication Response Models

struct InsightExtractionResponse {
    let insights: [ExtractedInsight]
    let deduplicationStats: DeduplicationStats
    let languageStats: LanguageProcessingStats
}

struct DeduplicationStats {
    let candidatesGenerated: Int
    var duplicatesFound: Int
    var insightsInserted: Int
    var insightsFused: Int
    var insightsRewritten: Int
    var raceConditionDuplicates: Int
}

struct LanguageProcessingStats {
    var detectedLanguages: [String: Int] // language code -> count
    var translatedCount: Int
}

struct ExtractedInsight {
    let content: String
    let category: String
    let subcategory: String?
    let wasTranslated: Bool
    let detectedLanguage: String
    let similarityScore: Float?
    let deduplicationAction: String // 'inserted', 'dropped', 'fused', 'rewritten'
}

// MARK: - Embedding Generation Models

struct EmbeddingGenerationResponse: Codable {
    let success: Bool
    let data: EmbeddingData?
    let error: String?
    let details: String?
}

struct EmbeddingData: Codable {
    let embedding: [Float]
    let detectedLanguage: String
    let wasTranslated: Bool
    let originalText: String
    let embeddedText: String
    let model: String
    let dimension: Int
    let processingTimeMs: Int
}

// MARK: - Similarity Check Models  

struct SimilarityCheckResponse: Codable {
    let success: Bool
    let data: SimilarityData?
    let error: String?
    let details: String?
}

struct SimilarityData: Codable {
    let similarInsights: [SimilarInsight]
    let recommendedAction: String
    let deduplicationPolicy: String
    let highestSimilarity: Float
    let searchTimeMs: Int
    let threshold: Float
    let totalFound: Int
}

struct SimilarInsight: Codable {
    let id: String
    let content: String
    let category: String
    let subcategory: String?
    let similarityScore: Float
    let wasTranslated: Bool
    let createdAt: String
}

class ContextualInsightService {
    static let shared = ContextualInsightService()
    
    /// Feature flag to use Edge Function instead of direct OpenAI API
    /// Default to true to support multi-provider API keys
    private let useEdgeFunction = UserDefaults.standard.object(forKey: "context_use_edge_function") as? Bool ?? true
    
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
        situationId: String? = nil
    ) async throws -> [ChildRegulationInsight] {
        print("🧠 Starting child regulation insights extraction for situation: \(situationId ?? "regeneration")")
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
        situationId: String? = nil
    ) async throws -> [ChildRegulationInsight] {
        print("🧠 Starting coping strategies extraction for situation: \(situationId ?? "regeneration")")
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
            print("🔍 Validating response encoding before returning...")
            
            // Double-check that the response is valid UTF-8
            if response.data(using: .utf8) != nil {
                print("✅ Response is valid UTF-8, safe to proceed")
                return response
            } else {
                print("❌ Response contains invalid UTF-8 characters from Edge Function!")
                throw ContextualInsightError.parsingError(NSError(domain: "UTF8ValidationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Response from Edge Function contains invalid UTF-8 characters"]))
            }
            
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
        situationId: String? = nil
    ) async throws -> [ContextualInsight] {
        print("🔍 Starting context extraction for situation: \(situationId ?? "regeneration")")
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
        
        // Debug: Log the full response content for analysis
        print("🔍 [DEBUG] Full context response content:")
        print("📝 Response length: \(content.count) characters")
        print("📝 Response preview (first 1000 chars): \(content.prefix(1000))")
        print("📝 Response sample (last 500 chars): \(content.suffix(500))")
        print("🔍 [DEBUG] =====================================")
        
        // Parse the 14-section response into contextual insights using existing logic
        let insights = parseContextResponse(
            content: content,
            familyId: familyId,
            childId: childId,
            situationId: situationId
        )
        
        print("✅ Parsed \(insights.count) contextual insights from \(content.count) chars")
        if insights.isEmpty {
            print("⚠️ WARNING: Zero insights parsed! This suggests a format mismatch.")
            print("⚠️ Check the Edge Function response format above.")
        }
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
            print("🔍 Response preview: \(response.prefix(200))...")
            print("🔍 Response length: \(response.count)")
            print("🔍 Validating response encoding before returning...")
            
            // Double-check that the response is valid UTF-8
            if response.data(using: .utf8) != nil {
                print("✅ Response is valid UTF-8, safe to proceed")
                return response
            } else {
                print("❌ Response contains invalid UTF-8 characters from Edge Function!")
                throw ContextualInsightError.parsingError(NSError(domain: "UTF8ValidationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Context response from Edge Function contains invalid UTF-8 characters"]))
            }
            
        } catch {
            print("❌ Edge Function context extraction failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let errorData = error as? EdgeFunctionError {
                print("❌ EdgeFunctionError: \(errorData)")
            }
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
        situationId: String?
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
        situationId: String?
    ) throws -> [ChildRegulationInsight] {
        print("🧠 Parsing regulation insights JSON response...")
        
        // Try to parse as JSON first
        print("🔍 Attempting to parse regulation response content:")
        print("🔍 Content preview: \(content.prefix(300))...")
        print("🔍 Content length: \(content.count)")
        
        guard let jsonData = content.data(using: .utf8) else {
            print("❌ Could not convert response to data")
            print("❌ Content appears to be invalid UTF-8")
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
        situationId: String?
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
        situationId: String?
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
            print("🔍 [PARSING] Looking for section: '\(sectionKey)'")
            if let extractedContent = extractSectionContent(from: content, sectionKey: sectionKey) {
                print("✅ [PARSING] Found content for '\(sectionKey)': \(extractedContent.prefix(100))...")
                
                // Skip "none found" responses
                if extractedContent.lowercased().contains("none found") {
                    print("⚠️ [PARSING] Skipping '\(sectionKey)' - contains 'none found'")
                    continue
                }
                
                // Split multiple insights if separated by newlines or bullets
                let individualInsights = splitInsights(extractedContent)
                print("📝 [PARSING] Split into \(individualInsights.count) individual insights")
                
                for insightText in individualInsights {
                    if let insight = createInsight(
                        text: insightText,
                        sectionKey: sectionKey,
                        familyId: familyId,
                        childId: childId,
                        situationId: situationId
                    ) {
                        insights.append(insight)
                        print("✅ [PARSING] Created insight: \(insightText.prefix(50))...")
                    } else {
                        print("❌ [PARSING] Failed to create insight from: \(insightText.prefix(50))...")
                    }
                }
            } else {
                print("❌ [PARSING] No content extracted for section: '\(sectionKey)'")
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
        situationId: String?
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
            
            // Archive to appropriate deleted table based on category
            switch insight.category {
            case .copingStrategies:
                print("🎯 This is a coping strategy - archiving before deletion")
                let deletedStrategy = DeletedCopingStrategy(from: insight)
                try await saveDeletedCopingStrategy(deletedStrategy)
                print("📦 Archived coping strategy before deletion: \(id)")
                
            case .core:
                print("🎯 This is an emotional regulation insight - archiving before deletion")
                let deletedInsight = DeletedEmotionalRegulationInsight(from: insight)
                try await saveDeletedEmotionalRegulationInsight(deletedInsight)
                print("📦 Archived emotional regulation insight before deletion: \(id)")
                
            case .adhd:
                print("🎯 This is an attention focus insight - archiving before deletion")
                let deletedInsight = DeletedAttentionFocusInsight(from: insight)
                try await saveDeletedAttentionFocusInsight(deletedInsight)
                print("📦 Archived attention focus insight before deletion: \(id)")
                
            case .mildAutism:
                print("🎯 This is a flexibility social insight - archiving before deletion")
                let deletedInsight = DeletedFlexibilitySocialInsight(from: insight)
                try await saveDeletedFlexibilitySocialInsight(deletedInsight)
                print("📦 Archived flexibility social insight before deletion: \(id)")
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
    
    /// Save a deleted emotional regulation insight to the archive table
    private func saveDeletedEmotionalRegulationInsight(_ deletedInsight: DeletedEmotionalRegulationInsight) async throws {
        print("📦 Saving deleted emotional regulation insight to archive: \(deletedInsight.id)")
        
        try await SupabaseManager.shared.client
            .from("deleted_emotional_regulation_insights")
            .insert(deletedInsight)
            .execute()
        
        print("✅ Successfully archived deleted emotional regulation insight")
    }
    
    /// Save a deleted attention focus insight to the archive table
    private func saveDeletedAttentionFocusInsight(_ deletedInsight: DeletedAttentionFocusInsight) async throws {
        print("📦 Saving deleted attention focus insight to archive: \(deletedInsight.id)")
        
        try await SupabaseManager.shared.client
            .from("deleted_attention_focus_insights")
            .insert(deletedInsight)
            .execute()
        
        print("✅ Successfully archived deleted attention focus insight")
    }
    
    /// Save a deleted flexibility social insight to the archive table
    private func saveDeletedFlexibilitySocialInsight(_ deletedInsight: DeletedFlexibilitySocialInsight) async throws {
        print("📦 Saving deleted flexibility social insight to archive: \(deletedInsight.id)")
        
        try await SupabaseManager.shared.client
            .from("deleted_flexibility_social_insights")
            .insert(deletedInsight)
            .execute()
        
        print("✅ Successfully archived deleted flexibility social insight")
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
    
    // MARK: - Deleted Emotional Regulation Insights Management
    
    /// Get all deleted emotional regulation insights for a family
    func getDeletedEmotionalRegulationInsights(familyId: String) async throws -> [DeletedEmotionalRegulationInsight] {
        print("📋 Fetching deleted emotional regulation insights for family: \(familyId)")
        
        do {
            let deletedInsights: [DeletedEmotionalRegulationInsight] = try await SupabaseManager.shared.client
                .from("deleted_emotional_regulation_insights")
                .select("*")
                .eq("family_id", value: familyId.lowercased())
                .order("deleted_at", ascending: false)
                .execute()
                .value
            
            print("✅ Found \(deletedInsights.count) deleted emotional regulation insights for family: \(familyId)")
            return deletedInsights
        } catch {
            print("❌ Error fetching deleted emotional regulation insights: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Restore a deleted emotional regulation insight back to the main table
    func restoreDeletedEmotionalRegulationInsight(id: String) async throws {
        print("♻️ Restoring deleted emotional regulation insight: \(id)")
        
        do {
            // Get the deleted insight
            let deletedInsight: DeletedEmotionalRegulationInsight = try await SupabaseManager.shared.client
                .from("deleted_emotional_regulation_insights")
                .select("*")
                .eq("id", value: id)
                .single()
                .execute()
                .value
            
            // Convert back to ChildRegulationInsight and save
            let restoredInsight = deletedInsight.toChildRegulationInsight()
            try await saveChildRegulationInsights([restoredInsight])
            
            // Remove from deleted table
            try await SupabaseManager.shared.client
                .from("deleted_emotional_regulation_insights")
                .delete()
                .eq("id", value: id)
                .execute()
            
            print("✅ Successfully restored emotional regulation insight: \(id)")
        } catch {
            print("❌ Error restoring deleted emotional regulation insight: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Permanently delete an emotional regulation insight from the deleted archive
    func permanentlyDeleteEmotionalRegulationInsight(id: String) async throws {
        print("🗑️ Permanently deleting emotional regulation insight from archive: \(id)")
        
        do {
            try await SupabaseManager.shared.client
                .from("deleted_emotional_regulation_insights")
                .delete()
                .eq("id", value: id)
                .execute()
            
            print("✅ Successfully permanently deleted emotional regulation insight: \(id)")
        } catch {
            print("❌ Error permanently deleting emotional regulation insight: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    // MARK: - Deleted Attention Focus Insights Management
    
    /// Get all deleted attention focus insights for a family
    func getDeletedAttentionFocusInsights(familyId: String) async throws -> [DeletedAttentionFocusInsight] {
        print("📋 Fetching deleted attention focus insights for family: \(familyId)")
        
        do {
            let deletedInsights: [DeletedAttentionFocusInsight] = try await SupabaseManager.shared.client
                .from("deleted_attention_focus_insights")
                .select("*")
                .eq("family_id", value: familyId.lowercased())
                .order("deleted_at", ascending: false)
                .execute()
                .value
            
            print("✅ Found \(deletedInsights.count) deleted attention focus insights for family: \(familyId)")
            return deletedInsights
        } catch {
            print("❌ Error fetching deleted attention focus insights: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Restore a deleted attention focus insight back to the main table
    func restoreDeletedAttentionFocusInsight(id: String) async throws {
        print("♻️ Restoring deleted attention focus insight: \(id)")
        
        do {
            // Get the deleted insight
            let deletedInsight: DeletedAttentionFocusInsight = try await SupabaseManager.shared.client
                .from("deleted_attention_focus_insights")
                .select("*")
                .eq("id", value: id)
                .single()
                .execute()
                .value
            
            // Convert back to ChildRegulationInsight and save
            let restoredInsight = deletedInsight.toChildRegulationInsight()
            try await saveChildRegulationInsights([restoredInsight])
            
            // Remove from deleted table
            try await SupabaseManager.shared.client
                .from("deleted_attention_focus_insights")
                .delete()
                .eq("id", value: id)
                .execute()
            
            print("✅ Successfully restored attention focus insight: \(id)")
        } catch {
            print("❌ Error restoring deleted attention focus insight: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Permanently delete an attention focus insight from the deleted archive
    func permanentlyDeleteAttentionFocusInsight(id: String) async throws {
        print("🗑️ Permanently deleting attention focus insight from archive: \(id)")
        
        do {
            try await SupabaseManager.shared.client
                .from("deleted_attention_focus_insights")
                .delete()
                .eq("id", value: id)
                .execute()
            
            print("✅ Successfully permanently deleted attention focus insight: \(id)")
        } catch {
            print("❌ Error permanently deleting attention focus insight: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    // MARK: - Deleted Flexibility Social Insights Management
    
    /// Get all deleted flexibility social insights for a family
    func getDeletedFlexibilitySocialInsights(familyId: String) async throws -> [DeletedFlexibilitySocialInsight] {
        print("📋 Fetching deleted flexibility social insights for family: \(familyId)")
        
        do {
            let deletedInsights: [DeletedFlexibilitySocialInsight] = try await SupabaseManager.shared.client
                .from("deleted_flexibility_social_insights")
                .select("*")
                .eq("family_id", value: familyId.lowercased())
                .order("deleted_at", ascending: false)
                .execute()
                .value
            
            print("✅ Found \(deletedInsights.count) deleted flexibility social insights for family: \(familyId)")
            return deletedInsights
        } catch {
            print("❌ Error fetching deleted flexibility social insights: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Restore a deleted flexibility social insight back to the main table
    func restoreDeletedFlexibilitySocialInsight(id: String) async throws {
        print("♻️ Restoring deleted flexibility social insight: \(id)")
        
        do {
            // Get the deleted insight
            let deletedInsight: DeletedFlexibilitySocialInsight = try await SupabaseManager.shared.client
                .from("deleted_flexibility_social_insights")
                .select("*")
                .eq("id", value: id)
                .single()
                .execute()
                .value
            
            // Convert back to ChildRegulationInsight and save
            let restoredInsight = deletedInsight.toChildRegulationInsight()
            try await saveChildRegulationInsights([restoredInsight])
            
            // Remove from deleted table
            try await SupabaseManager.shared.client
                .from("deleted_flexibility_social_insights")
                .delete()
                .eq("id", value: id)
                .execute()
            
            print("✅ Successfully restored flexibility social insight: \(id)")
        } catch {
            print("❌ Error restoring deleted flexibility social insight: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Permanently delete a flexibility social insight from the deleted archive
    func permanentlyDeleteFlexibilitySocialInsight(id: String) async throws {
        print("🗑️ Permanently deleting flexibility social insight from archive: \(id)")
        
        do {
            try await SupabaseManager.shared.client
                .from("deleted_flexibility_social_insights")
                .delete()
                .eq("id", value: id)
                .execute()
            
            print("✅ Successfully permanently deleted flexibility social insight: \(id)")
        } catch {
            print("❌ Error permanently deleting flexibility social insight: \(error)")
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
        print("🗑️ Deleting contextual insight: \(id)")
        
        do {
            print("🔍 Fetching insight details for archiving: \(id)")
            // First, get the insight to archive it
            let insight: ContextualInsight = try await SupabaseManager.shared.client
                .from("contextual_insights")
                .select("*")
                .eq("id", value: id)
                .single()
                .execute()
                .value
            
            print("✅ Found insight with category: \(insight.category.displayName)")
            
            // Archive the insight before deletion
            print("📦 Archiving contextual insight before deletion")
            let deletedInsight = DeletedContextualInsight(from: insight)
            try await saveDeletedContextualInsight(deletedInsight)
            print("📦 Archived contextual insight before deletion: \(id)")
            
            print("🗑️ Now deleting from main table...")
            // Then delete from main table
            try await SupabaseManager.shared.client
                .from("contextual_insights")
                .delete()
                .eq("id", value: id)
                .execute()
            
            print("✅ Successfully deleted contextual insight: \(id)")
        } catch {
            print("❌ Error deleting contextual insight: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    // MARK: - Deleted Contextual Insights Management
    
    /// Save a deleted contextual insight to the archive table
    private func saveDeletedContextualInsight(_ deletedInsight: DeletedContextualInsight) async throws {
        print("📦 Saving deleted contextual insight to archive: \(deletedInsight.id)")
        
        try await SupabaseManager.shared.client
            .from("deleted_contextual_insights")
            .insert(deletedInsight)
            .execute()
        
        print("✅ Successfully archived deleted contextual insight")
    }
    
    /// Get all deleted contextual insights for a family
    func getAllDeletedContextualInsights(familyId: String) async throws -> [DeletedContextualInsight] {
        print("📋 Fetching all deleted contextual insights for family: \(familyId)")
        
        do {
            let deletedInsights: [DeletedContextualInsight] = try await SupabaseManager.shared.client
                .from("deleted_contextual_insights")
                .select("*")
                .eq("family_id", value: familyId.lowercased())
                .order("deleted_at", ascending: false)
                .execute()
                .value
            
            print("✅ Found \(deletedInsights.count) deleted contextual insights for family: \(familyId)")
            return deletedInsights
        } catch {
            print("❌ Error fetching deleted contextual insights: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Get deleted contextual insights for a family filtered by category
    func getDeletedContextualInsights(familyId: String, category: ContextCategory? = nil) async throws -> [DeletedContextualInsight] {
        let categoryFilter = category?.rawValue ?? "all"
        print("📋 Fetching deleted contextual insights for family: \(familyId), category: \(categoryFilter)")
        
        do {
            var query = SupabaseManager.shared.client
                .from("deleted_contextual_insights")
                .select("*")
                .eq("family_id", value: familyId.lowercased())
            
            if let category = category {
                query = query.eq("category", value: category.rawValue)
            }
            
            let deletedInsights: [DeletedContextualInsight] = try await query
                .order("deleted_at", ascending: false)
                .execute()
                .value
            
            print("✅ Found \(deletedInsights.count) deleted contextual insights for family: \(familyId), category: \(categoryFilter)")
            return deletedInsights
        } catch {
            print("❌ Error fetching deleted contextual insights: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Restore a deleted contextual insight back to the main table
    func restoreDeletedContextualInsight(id: String) async throws {
        print("♻️ Restoring deleted contextual insight: \(id)")
        
        do {
            // Get the deleted insight
            let deletedInsight: DeletedContextualInsight = try await SupabaseManager.shared.client
                .from("deleted_contextual_insights")
                .select("*")
                .eq("id", value: id)
                .single()
                .execute()
                .value
            
            // Convert back to ContextualInsight and save
            let restoredInsight = deletedInsight.toContextualInsight()
            try await saveContextInsights([restoredInsight])
            
            // Remove from deleted table
            try await SupabaseManager.shared.client
                .from("deleted_contextual_insights")
                .delete()
                .eq("id", value: id)
                .execute()
            
            print("✅ Successfully restored contextual insight: \(id)")
        } catch {
            print("❌ Error restoring deleted contextual insight: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Permanently delete a contextual insight from the deleted archive
    func permanentlyDeleteContextualInsight(id: String) async throws {
        print("🗑️ Permanently deleting contextual insight from archive: \(id)")
        
        do {
            try await SupabaseManager.shared.client
                .from("deleted_contextual_insights")
                .delete()
                .eq("id", value: id)
                .execute()
            
            print("✅ Successfully permanently deleted contextual insight: \(id)")
        } catch {
            print("❌ Error permanently deleting contextual insight: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Permanently delete all contextual insights from the deleted archive
    func permanentlyDeleteAllDeletedContextualInsights(familyId: String, category: ContextCategory? = nil) async throws {
        print("🗑️ Permanently deleting all contextual insights from archive for family: \(familyId), category: \(category?.rawValue ?? "all")")
        
        do {
            var query = SupabaseManager.shared.client
                .from("deleted_contextual_insights")
                .delete()
                .eq("family_id", value: familyId)
            
            if let category = category {
                query = query.eq("category", value: category.rawValue)
            }
            
            try await query.execute()
            
            let categoryFilter = category?.rawValue ?? "all categories"
            print("✅ Successfully permanently deleted all contextual insights for \(categoryFilter)")
        } catch {
            print("❌ Error permanently deleting all contextual insights: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Permanently delete all deleted coping strategies
    func permanentlyDeleteAllDeletedCopingStrategies(familyId: String) async throws {
        print("🗑️ Permanently deleting all coping strategies from archive for family: \(familyId)")
        
        do {
            try await SupabaseManager.shared.client
                .from("deleted_coping_strategies")
                .delete()
                .eq("family_id", value: familyId)
                .execute()
            
            print("✅ Successfully permanently deleted all coping strategies")
        } catch {
            print("❌ Error permanently deleting all coping strategies: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Permanently delete all deleted emotional regulation insights
    func permanentlyDeleteAllDeletedEmotionalRegulationInsights(familyId: String) async throws {
        print("🗑️ Permanently deleting all emotional regulation insights from archive for family: \(familyId)")
        
        do {
            try await SupabaseManager.shared.client
                .from("deleted_emotional_regulation_insights")
                .delete()
                .eq("family_id", value: familyId)
                .execute()
            
            print("✅ Successfully permanently deleted all emotional regulation insights")
        } catch {
            print("❌ Error permanently deleting all emotional regulation insights: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Permanently delete all deleted attention focus insights
    func permanentlyDeleteAllDeletedAttentionFocusInsights(familyId: String) async throws {
        print("🗑️ Permanently deleting all attention focus insights from archive for family: \(familyId)")
        
        do {
            try await SupabaseManager.shared.client
                .from("deleted_attention_focus_insights")
                .delete()
                .eq("family_id", value: familyId)
                .execute()
            
            print("✅ Successfully permanently deleted all attention focus insights")
        } catch {
            print("❌ Error permanently deleting all attention focus insights: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Permanently delete all deleted flexibility social insights
    func permanentlyDeleteAllDeletedFlexibilitySocialInsights(familyId: String) async throws {
        print("🗑️ Permanently deleting all flexibility social insights from archive for family: \(familyId)")
        
        do {
            try await SupabaseManager.shared.client
                .from("deleted_flexibility_social_insights")
                .delete()
                .eq("family_id", value: familyId)
                .execute()
            
            print("✅ Successfully permanently deleted all flexibility social insights")
        } catch {
            print("❌ Error permanently deleting all flexibility social insights: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    // MARK: - Insight Regeneration Methods
    
    /// Regenerate all regulation insights from all user situations
    func regenerateAllRegulationInsights(familyId: String, apiKey: String) async throws -> (emotional: Int, attention: Int, flexibility: Int, coping: Int) {
        print("🔄 Starting batched regeneration of all regulation insights for family: \(familyId)")
        
        // 1. Fetch all situations for this family
        let situations = try await ConversationService.shared.getAllSituations(familyId: familyId)
        guard !situations.isEmpty else {
            print("⚠️ No situations found for family: \(familyId)")
            return (0, 0, 0, 0)
        }
        
        // 2. Filter out empty situations
        let validSituations = situations.filter { 
            !$0.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
        }
        
        guard !validSituations.isEmpty else {
            print("⚠️ No valid situation content found for family: \(familyId)")
            return (0, 0, 0, 0)
        }
        
        print("📝 Processing \(validSituations.count) valid situations")
        
        // 3. Clear existing regulation insights (not deleted ones)
        try await clearActiveRegulationInsights(familyId: familyId)
        
        // 4. Process situations in batches to avoid API limits
        let batchSize = 10 // Process 10 situations at a time to stay within API limits
        var allRegulationInsights: [ChildRegulationInsight] = []
        var allCopingInsights: [ChildRegulationInsight] = []
        
        for batchIndex in stride(from: 0, to: validSituations.count, by: batchSize) {
            let endIndex = min(batchIndex + batchSize, validSituations.count)
            let batch = Array(validSituations[batchIndex..<endIndex])
            
            print("🔄 Processing regulation batch \(batchIndex/batchSize + 1) of \(Int(ceil(Double(validSituations.count)/Double(batchSize)))): \(batch.count) situations")
            
            // Combine situations in this batch
            let batchText = batch
                .map { $0.description }
                .joined(separator: "\n\n---\n\n")
            
            print("📝 Batch text length: \(batchText.count) characters")
            
            // Process this batch for regulation insights
            do {
                let batchRegulationInsights = try await extractChildRegulationInsights(
                    situationText: batchText,
                    apiKey: apiKey,
                    familyId: familyId,
                    childId: nil,
                    situationId: nil
                )
                
                allRegulationInsights.append(contentsOf: batchRegulationInsights)
                print("✅ Regulation batch \(batchIndex/batchSize + 1) completed: \(batchRegulationInsights.count) insights extracted")
                
                // Also extract coping strategies from this batch
                let batchCopingInsights = try await extractCopingStrategies(
                    situationText: batchText,
                    apiKey: apiKey,
                    familyId: familyId,
                    childId: nil,
                    situationId: nil
                )
                
                allCopingInsights.append(contentsOf: batchCopingInsights)
                print("✅ Coping batch \(batchIndex/batchSize + 1) completed: \(batchCopingInsights.count) insights extracted")
                
                // Add a small delay between batches to avoid overwhelming the API
                if endIndex < validSituations.count {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                }
                
            } catch {
                print("❌ Error processing regulation batch \(batchIndex/batchSize + 1): \(error)")
                // Continue with next batch instead of failing completely
                continue
            }
        }
        
        // 5. Save all extracted insights to the database
        let allInsights = allRegulationInsights + allCopingInsights
        if !allInsights.isEmpty {
            print("💾 Saving \(allInsights.count) regulation insights to database...")
            try await saveChildRegulationInsights(allInsights)
            print("✅ Successfully saved all regulation insights to database")
        } else {
            print("⚠️ No regulation insights to save")
        }
        
        // 6. Count insights by category
        let emotionalCount = allRegulationInsights.filter { $0.category == .core }.count
        let attentionCount = allRegulationInsights.filter { $0.category == .adhd }.count
        let flexibilityCount = allRegulationInsights.filter { $0.category == .mildAutism }.count
        let copingCount = allCopingInsights.count
        
        print("✅ Batched regulation regeneration completed: \(emotionalCount) emotional, \(attentionCount) attention, \(flexibilityCount) flexibility, \(copingCount) coping")
        return (emotionalCount, attentionCount, flexibilityCount, copingCount)
    }
    
    /// Regenerate all contextual insights from all user situations
    func regenerateAllContextualInsights(familyId: String, apiKey: String) async throws -> [ContextCategory: Int] {
        print("🔄 Starting batched regeneration of all contextual insights for family: \(familyId)")
        
        // 1. Fetch all situations for this family
        let situations = try await ConversationService.shared.getAllSituations(familyId: familyId)
        guard !situations.isEmpty else {
            print("⚠️ No situations found for family: \(familyId)")
            return [:]
        }
        
        // 2. Filter out empty situations
        let validSituations = situations.filter { 
            !$0.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
        }
        
        guard !validSituations.isEmpty else {
            print("⚠️ No valid situation content found for family: \(familyId)")
            return [:]
        }
        
        print("📝 Processing \(validSituations.count) valid situations")
        
        // 3. Clear existing contextual insights (not deleted ones)
        try await clearActiveContextualInsights(familyId: familyId)
        
        // 4. Process situations in batches to avoid API limits
        let batchSize = 10 // Process 10 situations at a time to stay within API limits
        var allInsights: [ContextualInsight] = []
        
        for batchIndex in stride(from: 0, to: validSituations.count, by: batchSize) {
            let endIndex = min(batchIndex + batchSize, validSituations.count)
            let batch = Array(validSituations[batchIndex..<endIndex])
            
            print("🔄 Processing batch \(batchIndex/batchSize + 1) of \(Int(ceil(Double(validSituations.count)/Double(batchSize)))): \(batch.count) situations")
            
            // Combine situations in this batch
            let batchText = batch
                .map { $0.description }
                .joined(separator: "\n\n---\n\n")
            
            print("📝 Batch text length: \(batchText.count) characters")
            
            // Process this batch
            do {
                let batchInsights = try await extractContextFromSituation(
                    situationText: batchText,
                    apiKey: apiKey,
                    familyId: familyId,
                    childId: nil,
                    situationId: nil
                )
                
                allInsights.append(contentsOf: batchInsights)
                print("✅ Batch \(batchIndex/batchSize + 1) completed: \(batchInsights.count) insights extracted")
                
                // Add a small delay between batches to avoid overwhelming the API
                if endIndex < validSituations.count {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                }
                
            } catch {
                print("❌ Error processing batch \(batchIndex/batchSize + 1): \(error)")
                // Continue with next batch instead of failing completely
                continue
            }
        }
        
        // 5. Save all extracted insights to the database
        if !allInsights.isEmpty {
            print("💾 Saving \(allInsights.count) contextual insights to database...")
            try await saveContextInsights(allInsights)
            print("✅ Successfully saved all contextual insights to database")
        } else {
            print("⚠️ No contextual insights to save")
        }
        
        // 6. Count insights by category
        var counts: [ContextCategory: Int] = [:]
        for insight in allInsights {
            counts[insight.category, default: 0] += 1
        }
        
        print("✅ Batched regeneration completed: \(allInsights.count) contextual insights across \(counts.count) categories")
        return counts
    }
    
    /// Clear active regulation insights (not deleted ones)
    private func clearActiveRegulationInsights(familyId: String) async throws {
        print("🧹 Clearing active regulation insights for family: \(familyId)")
        
        // Clear all regulation insights from the insight_bullet_points table
        // This includes all regulation categories: core, adhd, mildAutism, and copingStrategies
        do {
            try await SupabaseManager.shared.client
                .from("insight_bullet_points")
                .delete()
                .eq("family_id", value: familyId)
                .execute()
            print("✅ Cleared all regulation insights from insight_bullet_points table")
        } catch {
            print("❌ Error clearing regulation insights: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    /// Clear active contextual insights (not deleted ones)
    private func clearActiveContextualInsights(familyId: String) async throws {
        print("🧹 Clearing active contextual insights for family: \(familyId)")
        
        do {
            try await SupabaseManager.shared.client
                .from("contextual_insights")
                .delete()
                .eq("family_id", value: familyId)
                .execute()
            print("✅ Cleared contextual insights")
        } catch {
            print("❌ Error clearing contextual insights: \(error)")
            throw ContextualInsightError.databaseError(error)
        }
    }
    
    // MARK: - Embedding and Deduplication Methods
    
    /// Generate vector embedding for text with multilingual support
    func generateEmbedding(
        text: String,
        apiKey: String,
        sourceLanguage: String? = nil
    ) async throws -> EmbeddingData {
        print("🧠 Generating embedding for text: \(text.prefix(100))...")
        
        // Choose implementation based on feature flag
        if useEdgeFunction {
            print("🚀 [ContextualInsightService] Using EdgeFunction for embedding generation")
            return try await generateEmbeddingViaEdgeFunction(
                text: text,
                apiKey: apiKey,
                sourceLanguage: sourceLanguage
            )
        } else {
            print("🔗 [ContextualInsightService] Direct embedding API not implemented - using EdgeFunction")
            return try await generateEmbeddingViaEdgeFunction(
                text: text,
                apiKey: apiKey,
                sourceLanguage: sourceLanguage
            )
        }
    }
    
    /// Check similarity against existing insights
    func checkSimilarity(
        embedding: [Float],
        familyId: String,
        category: String,
        tableName: String,
        subcategory: String? = nil,
        similarityThreshold: Float? = nil,
        apiKey: String
    ) async throws -> SimilarityData {
        print("🔍 Checking similarity for category: \(category) in table: \(tableName)")
        
        // Use EdgeFunction for similarity checking
        if useEdgeFunction {
            print("🚀 [ContextualInsightService] Using EdgeFunction for similarity check")
            return try await checkSimilarityViaEdgeFunction(
                embedding: embedding,
                familyId: familyId,
                category: category,
                tableName: tableName,
                subcategory: subcategory,
                similarityThreshold: similarityThreshold,
                apiKey: apiKey
            )
        } else {
            throw ContextualInsightError.apiError(501) // Not implemented for direct API
        }
    }
    
    /// Generate embedding via Edge Function
    private func generateEmbeddingViaEdgeFunction(
        text: String,
        apiKey: String,
        sourceLanguage: String? = nil
    ) async throws -> EmbeddingData {
        print("🔄 Using Edge Function for embedding generation")
        
        do {
            let response = try await EdgeFunctionService.shared.generateEmbedding(
                text: text,
                apiKey: apiKey,
                sourceLanguage: sourceLanguage
            )
            
            print("✅ Embedding generated via Edge Function")
            return response
            
        } catch {
            print("❌ Edge Function embedding generation failed: \(error)")
            throw ContextualInsightError.apiError(0)
        }
    }
    
    /// Check similarity via Edge Function
    private func checkSimilarityViaEdgeFunction(
        embedding: [Float],
        familyId: String,
        category: String,
        tableName: String,
        subcategory: String? = nil,
        similarityThreshold: Float? = nil,
        apiKey: String
    ) async throws -> SimilarityData {
        print("🔄 Using Edge Function for similarity check")
        
        do {
            let response = try await EdgeFunctionService.shared.checkSimilarity(
                embedding: embedding,
                familyId: familyId,
                category: category,
                tableName: tableName,
                subcategory: subcategory,
                similarityThreshold: similarityThreshold,
                apiKey: apiKey
            )
            
            print("✅ Similarity check completed via Edge Function")
            return response
            
        } catch {
            print("❌ Edge Function similarity check failed: \(error)")
            throw ContextualInsightError.apiError(0)
        }
    }
    
    /// Extract insights with deduplication (enhanced version)
    func extractInsightsWithDeduplication(
        situationText: String,
        apiKey: String,
        familyId: String,
        childId: String? = nil,
        situationId: String? = nil,
        userLanguage: String? = nil,
        extractionType: String = "general" // "general" or "regulation"
    ) async throws -> InsightExtractionResponse {
        print("🧠 Starting insight extraction with deduplication for situation: \(situationId ?? "regeneration")")
        print("📝 Situation text: \(situationText.prefix(100))...")
        print("🌐 User language: \(userLanguage ?? "auto-detect")")
        
        let startTime = Date()
        
        // Step 1: Extract candidate insights using existing logic
        let candidateInsights: [Any]
        let tableName: String
        
        if extractionType == "regulation" {
            candidateInsights = try await extractChildRegulationInsights(
                situationText: situationText,
                apiKey: apiKey,
                familyId: familyId,
                childId: childId,
                situationId: situationId
            )
            tableName = "insight_bullet_points"
        } else {
            candidateInsights = try await extractContextFromSituation(
                situationText: situationText,
                apiKey: apiKey,
                familyId: familyId,
                childId: childId,
                situationId: situationId
            )
            tableName = "contextual_insights"
        }
        
        print("📊 Generated \(candidateInsights.count) candidate insights")
        
        // Step 2: Process each candidate with deduplication
        var processedInsights: [ExtractedInsight] = []
        var deduplicationStats = DeduplicationStats(
            candidatesGenerated: candidateInsights.count,
            duplicatesFound: 0,
            insightsInserted: 0,
            insightsFused: 0,
            insightsRewritten: 0,
            raceConditionDuplicates: 0
        )
        var languageStats = LanguageProcessingStats(
            detectedLanguages: [:],
            translatedCount: 0
        )
        
        for candidate in candidateInsights {
            // Extract content and category from candidate
            let content: String
            let category: String
            let subcategory: String?
            
            if let regulationInsight = candidate as? ChildRegulationInsight {
                content = regulationInsight.content
                category = regulationInsight.category.rawValue
                subcategory = nil
            } else if let contextualInsight = candidate as? ContextualInsight {
                content = contextualInsight.content
                category = contextualInsight.category.rawValue
                subcategory = contextualInsight.subcategory?.rawValue
            } else {
                continue // Skip unknown types
            }
            
            // Generate embedding for this candidate
            let embeddingData = try await generateEmbedding(
                text: content,
                apiKey: apiKey,
                sourceLanguage: userLanguage
            )
            
            // Update language statistics
            languageStats.detectedLanguages[embeddingData.detectedLanguage, default: 0] += 1
            if embeddingData.wasTranslated {
                languageStats.translatedCount += 1
            }
            
            // Check for similar insights
            let similarityData = try await checkSimilarity(
                embedding: embeddingData.embedding,
                familyId: familyId,
                category: category,
                tableName: tableName,
                subcategory: subcategory,
                apiKey: apiKey
            )
            
            // Apply deduplication policy
            let extractedInsight = ExtractedInsight(
                content: content,
                category: category,
                subcategory: subcategory,
                wasTranslated: embeddingData.wasTranslated,
                detectedLanguage: embeddingData.detectedLanguage,
                similarityScore: similarityData.highestSimilarity > 0 ? similarityData.highestSimilarity : nil,
                deduplicationAction: similarityData.recommendedAction
            )
            
            processedInsights.append(extractedInsight)
            
            // Update deduplication statistics
            if similarityData.totalFound > 0 {
                deduplicationStats.duplicatesFound += 1
                
                switch similarityData.recommendedAction {
                case "insert":
                    deduplicationStats.insightsInserted += 1
                case "fuse":
                    deduplicationStats.insightsFused += 1
                case "rewrite":
                    deduplicationStats.insightsRewritten += 1
                case "drop":
                    break // Don't count dropped insights as inserted
                default:
                    deduplicationStats.insightsInserted += 1
                }
            } else {
                deduplicationStats.insightsInserted += 1
            }
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        print("✅ Deduplication processing completed in \(Int(processingTime * 1000))ms")
        print("📊 Stats: \(deduplicationStats.duplicatesFound) duplicates found, \(deduplicationStats.insightsInserted) insights will be inserted")
        
        return InsightExtractionResponse(
            insights: processedInsights,
            deduplicationStats: deduplicationStats,
            languageStats: languageStats
        )
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