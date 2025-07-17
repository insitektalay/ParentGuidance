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
    
    private init() {}
    
    // MARK: - Context Extraction
    
    func extractContextFromSituation(
        situationText: String,
        apiKey: String,
        familyId: String,
        childId: String? = nil,
        situationId: String
    ) async throws -> [ContextualInsight] {
        print("🔍 Starting context extraction for situation: \(situationId)")
        print("📝 Situation text: \(situationText.prefix(100))...")
        
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
            
            // Parse the 14-section response into contextual insights
            let insights = parseContextResponse(
                content: content,
                familyId: familyId,
                childId: childId,
                situationId: situationId
            )
            
            print("✅ Parsed \(insights.count) contextual insights")
            return insights
            
        } catch {
            print("❌ Error parsing context extraction response: \(error)")
            throw ContextualInsightError.parsingError(error)
        }
    }
    
    // MARK: - Response Parsing
    
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