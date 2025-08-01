//
//  GuidanceGenerationService.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/07/2025.
//

import Foundation
import Combine

class GuidanceGenerationService {
    static let shared = GuidanceGenerationService()
    
    /// Feature flag to use Edge Function instead of direct OpenAI API
    private let useEdgeFunction = UserDefaults.standard.bool(forKey: "guidance_use_edge_function")
    
    private init() {}
    
    // MARK: - Configuration Methods
    
    /// Enable or disable Edge Function usage for guidance generation
    static func setUseEdgeFunction(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "guidance_use_edge_function")
        print("🔧 GuidanceGenerationService Edge Function usage set to: \(enabled)")
    }
    
    /// Check if Edge Function is currently enabled
    static func isUsingEdgeFunction() -> Bool {
        return UserDefaults.standard.bool(forKey: "guidance_use_edge_function")
    }
    
    // MARK: - Main Guidance Generation
    
    /// Generate guidance with optional streaming support
    func generateGuidance(
        situation: String,
        childContext: String? = nil,
        keyInsights: String? = nil,
        copingStrategies: String? = nil,
        apiKey: String,
        activeFramework: FrameworkRecommendation? = nil,
        situationType: SituationType = .imJustWondering,
        useStreaming: Bool = false
    ) async throws -> (GuidanceResponseProtocol, String) {
        
        let (guidance, rawContent): (GuidanceResponseProtocol, String)
        
        if useEdgeFunction && useStreaming {
            print("🚀 [GuidanceGenerationService] Using EdgeFunction with streaming")
            (guidance, rawContent) = try await generateGuidanceViaEdgeFunctionStreaming(
                situation: situation,
                childContext: childContext,
                keyInsights: keyInsights,
                copingStrategies: copingStrategies,
                apiKey: apiKey,
                activeFramework: activeFramework,
                situationType: situationType
            )
        } else if useEdgeFunction {
            print("🚀 [GuidanceGenerationService] Using EdgeFunction (non-streaming)")
            (guidance, rawContent) = try await generateGuidanceViaEdgeFunctionNonStreaming(
                situation: situation,
                childContext: childContext,
                keyInsights: keyInsights,
                copingStrategies: copingStrategies,
                apiKey: apiKey,
                activeFramework: activeFramework,
                situationType: situationType
            )
        } else {
            print("🔗 [GuidanceGenerationService] Using Direct API (legacy)")
            (guidance, rawContent) = try await generateGuidanceViaDirectAPI(
                situation: situation,
                childContext: childContext,
                keyInsights: keyInsights,
                copingStrategies: copingStrategies,
                apiKey: apiKey,
                activeFramework: activeFramework,
                situationType: situationType
            )
        }
        
        // Extract overall recommendation from the guidance content
        let enhancedGuidance = try await extractAndAddRecommendation(
            guidance: guidance,
            rawContent: rawContent,
            apiKey: apiKey
        )
        
        return (enhancedGuidance, rawContent)
    }
    
    /// Generate guidance and select relevant insights
    func generateGuidanceWithRelevantInsights(
        situation: String,
        situationId: String,
        familyId: String,
        childContext: String? = nil,
        keyInsights: String? = nil,
        copingStrategies: String? = nil,
        apiKey: String,
        activeFramework: FrameworkRecommendation? = nil,
        situationType: SituationType = .imJustWondering,
        useStreaming: Bool = false
    ) async throws -> (GuidanceResponseProtocol, String, String?) {
        
        // Step 1: Generate guidance as usual
        let (guidance, rawContent) = try await generateGuidance(
            situation: situation,
            childContext: childContext,
            keyInsights: keyInsights,
            copingStrategies: copingStrategies,
            apiKey: apiKey,
            activeFramework: activeFramework,
            situationType: situationType,
            useStreaming: useStreaming
        )
        
        // Step 2: Select relevant insights (if guidance has ID)
        var guidanceId: String? = nil
        
        // Extract guidance ID from the response if available
        // This would typically come from saving the guidance to the database first
        // For now, we'll generate a placeholder ID
        let tempGuidanceId = UUID().uuidString
        
        // Step 3: Select relevant insights using the raw guidance content
        do {
            let relevantInsights = try await RelevantInsightsService.shared.selectRelevantInsights(
                guidanceText: rawContent,
                situationId: situationId,
                guidanceId: tempGuidanceId,
                familyId: familyId,
                apiKey: apiKey
            )
            
            if !relevantInsights.isEmpty {
                guidanceId = tempGuidanceId
                print("✅ Selected \(relevantInsights.count) relevant insights for guidance")
            }
            
        } catch {
            print("⚠️ Failed to select relevant insights: \(error)")
            // Continue without relevant insights - non-blocking
        }
        
        return (guidance, rawContent, guidanceId)
    }
    
    /// Generate guidance with streaming updates via callback
    func generateGuidanceWithStreaming(
        situation: String,
        childContext: String? = nil,
        keyInsights: String? = nil,
        copingStrategies: String? = nil,
        apiKey: String,
        activeFramework: FrameworkRecommendation? = nil,
        situationType: SituationType = .imJustWondering,
        onUpdate: @escaping (String) -> Void,
        onComplete: @escaping (GuidanceResponseProtocol, String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        Task {
            do {
                if useEdgeFunction {
                    try await streamGuidanceViaEdgeFunction(
                        situation: situation,
                        childContext: childContext,
                        keyInsights: keyInsights,
                        copingStrategies: copingStrategies,
                        apiKey: apiKey,
                        activeFramework: activeFramework,
                        situationType: situationType,
                        onUpdate: onUpdate,
                        onComplete: onComplete
                    )
                } else {
                    // Fallback to non-streaming for direct API
                    let (guidance, rawContent) = try await generateGuidanceViaDirectAPI(
                        situation: situation,
                        childContext: childContext,
                        keyInsights: keyInsights,
                        copingStrategies: copingStrategies,
                        apiKey: apiKey,
                        activeFramework: activeFramework,
                        situationType: situationType
                    )
                    onComplete(guidance, rawContent)
                }
            } catch {
                onError(error)
            }
        }
    }
    
    // MARK: - Edge Function Implementation
    
    /// Generate guidance using EdgeFunction with streaming
    private func streamGuidanceViaEdgeFunction(
        situation: String,
        childContext: String?,
        keyInsights: String?,
        copingStrategies: String?,
        apiKey: String,
        activeFramework: FrameworkRecommendation?,
        situationType: SituationType,
        onUpdate: @escaping (String) -> Void,
        onComplete: @escaping (GuidanceResponseProtocol, String) -> Void
    ) async throws {
        print("🔄 Using Edge Function for guidance generation with streaming")
        
        var accumulatedContent = ""
        
        do {
            let guidanceStructureSettings = GuidanceStructureSettings.shared
            let structureMode = guidanceStructureSettings.currentMode == .fixed ? "fixed" : "dynamic"
            let guidanceStyle = guidanceStructureSettings.currentStyle == .warmPractical ? "Warm Practical" : "Analytical Scientific"
            
            print("📊 [GuidanceGenerationService] Current settings:")
            print("   → Structure Mode: \(structureMode)")
            print("   → Guidance Style: \(guidanceStyle)")
            print("   → Selected Prompt Version: \(guidanceStructureSettings.getPromptVersion(hasFramework: activeFramework != nil))")
            
            let stream = try await EdgeFunctionService.shared.streamGuidance(
                situation: situation,
                childContext: childContext,
                keyInsights: keyInsights,
                copingStrategies: copingStrategies,
                activeFramework: activeFramework,
                structureMode: structureMode,
                guidanceStyle: guidanceStyle,
                situationType: situationType,
                apiKey: apiKey
            )
            
            for try await chunk in stream {
                accumulatedContent += chunk
                await MainActor.run {
                    onUpdate(chunk)
                }
            }
            
            // Parse the complete response
            let guidance = try parseGuidanceResponse(accumulatedContent)
            let finalContent = accumulatedContent
            
            await MainActor.run {
                onComplete(guidance, finalContent)
            }
            
            print("✅ Streaming guidance generation completed via Edge Function")
            
        } catch {
            print("❌ Edge Function streaming guidance generation failed: \(error)")
            throw GuidanceGenerationError.streamingError(error.localizedDescription)
        }
    }
    
    /// Generate guidance using EdgeFunction without streaming (for compatibility)
    private func generateGuidanceViaEdgeFunctionStreaming(
        situation: String,
        childContext: String?,
        keyInsights: String?,
        copingStrategies: String?,
        apiKey: String,
        activeFramework: FrameworkRecommendation?,
        situationType: SituationType
    ) async throws -> (GuidanceResponseProtocol, String) {
        print("🔄 Using Edge Function for guidance generation (collecting streaming)")
        
        var accumulatedContent = ""
        
        do {
            let guidanceStructureSettings = GuidanceStructureSettings.shared
            let structureMode = guidanceStructureSettings.currentMode == .fixed ? "fixed" : "dynamic"
            let guidanceStyle = guidanceStructureSettings.currentStyle == .warmPractical ? "Warm Practical" : "Analytical Scientific"
            
            print("📊 [GuidanceGenerationService] Current settings:")
            print("   → Structure Mode: \(structureMode)")
            print("   → Guidance Style: \(guidanceStyle)")
            print("   → Selected Prompt Version: \(guidanceStructureSettings.getPromptVersion(hasFramework: activeFramework != nil))")
            
            let stream = try await EdgeFunctionService.shared.streamGuidance(
                situation: situation,
                childContext: childContext,
                keyInsights: keyInsights,
                copingStrategies: copingStrategies,
                activeFramework: activeFramework,
                structureMode: structureMode,
                guidanceStyle: guidanceStyle,
                situationType: situationType,
                apiKey: apiKey
            )
            
            for try await chunk in stream {
                accumulatedContent += chunk
            }
            
            let guidance = try parseGuidanceResponse(accumulatedContent)
            print("✅ Edge Function guidance generation completed")
            
            return (guidance, accumulatedContent)
            
        } catch {
            print("❌ Edge Function guidance generation failed: \(error)")
            throw GuidanceGenerationError.apiError("Edge Function error: \(error.localizedDescription)")
        }
    }
    
    /// Generate guidance using EdgeFunction (non-streaming, for future use)
    private func generateGuidanceViaEdgeFunctionNonStreaming(
        situation: String,
        childContext: String?,
        keyInsights: String?,
        copingStrategies: String?,
        apiKey: String,
        activeFramework: FrameworkRecommendation?,
        situationType: SituationType
    ) async throws -> (GuidanceResponseProtocol, String) {
        // For now, use the streaming approach and collect all content
        return try await generateGuidanceViaEdgeFunctionStreaming(
            situation: situation,
            childContext: childContext,
            keyInsights: keyInsights,
            copingStrategies: copingStrategies,
            apiKey: apiKey,
            activeFramework: activeFramework,
            situationType: situationType
        )
    }
    
    // MARK: - Direct API Implementation (Legacy)
    
    /// Generate guidance using legacy direct API approach
    private func generateGuidanceViaDirectAPI(
        situation: String,
        childContext: String?,
        keyInsights: String?,
        copingStrategies: String?,
        apiKey: String,
        activeFramework: FrameworkRecommendation?,
        situationType: SituationType
    ) async throws -> (GuidanceResponseProtocol, String) {
        print("🔄 Using direct API for guidance generation (legacy)")
        
        // Prepend guidance note to situation for Direct API (since templates are server-side)
        let guidanceNote = situationType.guidanceNote
        let situationWithGuidance = "\(guidanceNote)\n\n\(situation)"
        
        print("🔍 [Direct API] Added guidance note for situation type: \(situationType.rawValue)")
        print("🔍 [Direct API] Guidance note: \(guidanceNote)")
        
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let guidanceStructureSettings = GuidanceStructureSettings.shared
        
        let (promptId, version, variables): (String, String, [String: Any]) = {
            if let framework = activeFramework {
                // With Framework - Choose version based on style and structure mode
                let version = guidanceStructureSettings.getPromptVersion(hasFramework: true)
                
                // Include psychologist notes if provided
                var variables: [String: Any] = [
                    "current_situation": situationWithGuidance,
                    "active_foundation_tools": formatFrameworkForPrompt(framework)
                ]
                if let childContext = childContext, !childContext.isEmpty {
                    variables["child_context"] = childContext
                }
                if let keyInsights = keyInsights, !keyInsights.isEmpty {
                    variables["key_insights"] = keyInsights
                }
                if let copingStrategies = copingStrategies, !copingStrategies.isEmpty {
                    variables["coping_strategies_home_consequences"] = copingStrategies
                }
                
                return (
                    "pmpt_68516f961dc08190aceb4f591ee010050a454989b0581453",
                    version,
                    variables
                )
            } else {
                // Without Framework - Choose version based on style and structure mode
                let version = guidanceStructureSettings.getPromptVersion(hasFramework: false)
                
                // Include psychologist notes if provided
                var variables: [String: Any] = [
                    "current_situation": situationWithGuidance
                ]
                if let childContext = childContext, !childContext.isEmpty {
                    variables["child_context"] = childContext
                }
                if let keyInsights = keyInsights, !keyInsights.isEmpty {
                    variables["key_insights"] = keyInsights
                }
                if let copingStrategies = copingStrategies, !copingStrategies.isEmpty {
                    variables["coping_strategies_home_consequences"] = copingStrategies
                }
                
                return (
                    "pmpt_68515280423c8193aaa00a07235b7cf206c51d869f9526ba",
                    version,
                    variables
                )
            }
        }()
        
        // Log the prompt variables for debugging
        print("🔍 ===== DIRECT API PROMPT VARIABLES =====")
        print("🔍 NOTE: Direct API uses OpenAI Prompts API - the full prompt")
        print("🔍 is constructed server-side by OpenAI, not locally.")
        print("🔍 Variables sent to OpenAI:")
        print("🔍 Prompt ID: \(promptId)")
        print("🔍 Version: \(version)")
        print("🔍 Variables: \(variables)")
        print("🔍 Has Framework: \(activeFramework != nil)")
        if let framework = activeFramework {
            print("🔍 Framework Name: \(framework.frameworkName)")
            print("🔍 Formatted Framework: \(formatFrameworkForPrompt(framework))")
        }
        print("🔍 Structure Mode: \(guidanceStructureSettings.currentMode)")
        print("🔍 Guidance Style: \(guidanceStructureSettings.currentStyle)")
        print("🔍 ==============================================")
        
        let requestBody: [String: Any] = [
            "prompt": [
                "id": promptId,
                "version": version,
                "variables": variables
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GuidanceGenerationError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
        
        guard let firstOutput = promptResponse.output.first,
              let firstContent = firstOutput.content.first else {
            throw GuidanceGenerationError.noContent
        }
        
        let content = firstContent.text
        let guidance = try parseGuidanceResponse(content)
        
        print("✅ Direct API guidance generation completed")
        return (guidance, content)
    }
    
    // MARK: - Helper Methods
    
    /// Extract overall recommendation and add it to the guidance
    private func extractAndAddRecommendation(
        guidance: GuidanceResponseProtocol,
        rawContent: String,
        apiKey: String
    ) async throws -> GuidanceResponseProtocol {
        do {
            print("🔍 [GuidanceGenerationService] ===== RECOMMENDATION EXTRACTION STARTS =====")
            print("🔍 [GuidanceGenerationService] useEdgeFunction: \(useEdgeFunction)")
            print("🔍 [GuidanceGenerationService] rawContent length: \(rawContent.count)")
            print("🔍 [GuidanceGenerationService] rawContent preview: \(String(rawContent.prefix(200)))...")
            
            let recommendation: String
            if useEdgeFunction {
                print("🚀 [GuidanceGenerationService] Using EdgeFunction for recommendation extraction")
                recommendation = try await EdgeFunctionService.shared.extractOverallRecommendation(
                    guidanceContent: rawContent,
                    apiKey: apiKey
                )
                print("✅ [GuidanceGenerationService] EdgeFunction returned recommendation: \(recommendation)")
            } else {
                print("🔗 [GuidanceGenerationService] Using Direct API for recommendation extraction")
                // For direct API, use a simple fallback extraction
                recommendation = try await extractRecommendationViaDirect(rawContent: rawContent, apiKey: apiKey)
                print("✅ [GuidanceGenerationService] Direct API returned recommendation: \(recommendation)")
            }
            
            // Parse the recommendation to extract just the content
            print("🔧 [GuidanceGenerationService] Parsing recommendation response...")
            let cleanedRecommendation = parseRecommendationResponse(recommendation)
            print("✅ [GuidanceGenerationService] Cleaned recommendation: \(cleanedRecommendation)")
            
            print("✅ [GuidanceGenerationService] Overall recommendation extracted successfully")
            
            // Create enhanced guidance with recommendation
            print("🔧 [GuidanceGenerationService] Creating enhanced guidance with recommendation...")
            let enhancedGuidance = createGuidanceWithRecommendation(original: guidance, recommendation: cleanedRecommendation)
            print("✅ [GuidanceGenerationService] Enhanced guidance created with recommendation")
            print("🔍 [GuidanceGenerationService] ===== RECOMMENDATION EXTRACTION COMPLETE =====")
            
            return enhancedGuidance
            
        } catch {
            print("⚠️ [GuidanceGenerationService] Failed to extract recommendation: \(error)")
            print("⚠️ Continuing without recommendation (non-blocking)")
            
            // Return original guidance without recommendation
            return guidance
        }
    }
    
    /// Parse recommendation response to extract clean content
    private func parseRecommendationResponse(_ response: String) -> String? {
        // Look for [Overall Recommendation] pattern
        let pattern = "\\[Overall Recommendation\\]\\s*\\n([\\s\\S]*?)(?=\\n\\s*\\[|$)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(response.startIndex..., in: response)
        
        if let match = regex?.firstMatch(in: response, options: [], range: range),
           let swiftRange = Range(match.range(at: 1), in: response) {
            let extracted = String(response[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            return extracted.isEmpty ? nil : extracted
        }
        
        // Fallback: if no bracket format, return the whole response (cleaned)
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
    
    /// Create guidance with recommendation added
    private func createGuidanceWithRecommendation(
        original: GuidanceResponseProtocol,
        recommendation: String?
    ) -> GuidanceResponseProtocol {
        if let dynamicGuidance = original as? DynamicGuidanceResponse {
            return DynamicGuidanceResponse(
                title: dynamicGuidance.title,
                sections: dynamicGuidance.sections,
                overallRecommendation: recommendation
            )
        } else if let fixedGuidance = original as? GuidanceResponse {
            return GuidanceResponse(
                title: fixedGuidance.title,
                situation: fixedGuidance.situation,
                analysis: fixedGuidance.analysis,
                actionSteps: fixedGuidance.actionSteps,
                phrasesToTry: fixedGuidance.phrasesToTry,
                quickComebacks: fixedGuidance.quickComebacks,
                support: fixedGuidance.support,
                overallRecommendation: recommendation
            )
        } else {
            // Fallback: return original if type is unknown
            return original
        }
    }
    
    /// Extract recommendation via direct API (fallback for legacy mode)
    private func extractRecommendationViaDirect(rawContent: String, apiKey: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "prompt": [
                "id": "pmpt_extract_rec",
                "version": "1",
                "variables": ["source_text": rawContent]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GuidanceGenerationError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
        
        guard let firstOutput = promptResponse.output.first,
              let firstContent = firstOutput.content.first else {
            throw GuidanceGenerationError.noContent
        }
        
        return firstContent.text
    }
    
    /// Parse guidance response from raw content
    private func parseGuidanceResponse(_ content: String) throws -> GuidanceResponseProtocol {
        guard let guidance = DynamicGuidanceParser.shared.parseWithFallback(content) else {
            throw GuidanceGenerationError.parsingError
        }
        
        return guidance
    }
    
    /// Format framework for prompt (legacy compatibility)
    private func formatFrameworkForPrompt(_ framework: FrameworkRecommendation) -> String {
        return framework.frameworkName
    }
}

// MARK: - Error Types

enum GuidanceGenerationError: Error, LocalizedError {
    case apiError(String)
    case httpError(Int)
    case noContent
    case parsingError
    case streamingError(String)
    
    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return "API Error: \(message)"
        case .httpError(let statusCode):
            return "HTTP Error: \(statusCode)"
        case .noContent:
            return "No content received from guidance generation"
        case .parsingError:
            return "Failed to parse guidance response"
        case .streamingError(let message):
            return "Streaming Error: \(message)"
        }
    }
}
