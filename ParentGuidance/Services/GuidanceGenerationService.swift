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
        apiKey: String,
        activeFramework: FrameworkRecommendation? = nil,
        useStreaming: Bool = false
    ) async throws -> (GuidanceResponseProtocol, String) {
        
        if useEdgeFunction && useStreaming {
            print("🚀 [GuidanceGenerationService] Using EdgeFunction with streaming")
            return try await generateGuidanceViaEdgeFunctionStreaming(
                situation: situation,
                childContext: childContext,
                keyInsights: keyInsights,
                apiKey: apiKey,
                activeFramework: activeFramework
            )
        } else if useEdgeFunction {
            print("🚀 [GuidanceGenerationService] Using EdgeFunction (non-streaming)")
            return try await generateGuidanceViaEdgeFunctionNonStreaming(
                situation: situation,
                childContext: childContext,
                keyInsights: keyInsights,
                apiKey: apiKey,
                activeFramework: activeFramework
            )
        } else {
            print("🔗 [GuidanceGenerationService] Using Direct API (legacy)")
            return try await generateGuidanceViaDirectAPI(
                situation: situation,
                childContext: childContext,
                keyInsights: keyInsights,
                apiKey: apiKey,
                activeFramework: activeFramework
            )
        }
    }
    
    /// Generate guidance with streaming updates via callback
    func generateGuidanceWithStreaming(
        situation: String,
        childContext: String? = nil,
        keyInsights: String? = nil,
        apiKey: String,
        activeFramework: FrameworkRecommendation? = nil,
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
                        apiKey: apiKey,
                        activeFramework: activeFramework,
                        onUpdate: onUpdate,
                        onComplete: onComplete
                    )
                } else {
                    // Fallback to non-streaming for direct API
                    let (guidance, rawContent) = try await generateGuidanceViaDirectAPI(
                        situation: situation,
                        childContext: childContext,
                        keyInsights: keyInsights,
                        apiKey: apiKey,
                        activeFramework: activeFramework
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
        apiKey: String,
        activeFramework: FrameworkRecommendation?,
        onUpdate: @escaping (String) -> Void,
        onComplete: @escaping (GuidanceResponseProtocol, String) -> Void
    ) async throws {
        print("🔄 Using Edge Function for guidance generation with streaming")
        
        var accumulatedContent = ""
        
        do {
            let guidanceStructureSettings = GuidanceStructureSettings.shared
            let structureMode = guidanceStructureSettings.currentMode == .fixed ? "fixed" : "dynamic"
            
            let stream = try await EdgeFunctionService.shared.streamGuidance(
                situation: situation,
                childContext: childContext,
                keyInsights: keyInsights,
                activeFramework: activeFramework,
                structureMode: structureMode,
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
        apiKey: String,
        activeFramework: FrameworkRecommendation?
    ) async throws -> (GuidanceResponseProtocol, String) {
        print("🔄 Using Edge Function for guidance generation (collecting streaming)")
        
        var accumulatedContent = ""
        
        do {
            let guidanceStructureSettings = GuidanceStructureSettings.shared
            let structureMode = guidanceStructureSettings.currentMode == .fixed ? "fixed" : "dynamic"
            
            let stream = try await EdgeFunctionService.shared.streamGuidance(
                situation: situation,
                childContext: childContext,
                keyInsights: keyInsights,
                activeFramework: activeFramework,
                structureMode: structureMode,
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
        apiKey: String,
        activeFramework: FrameworkRecommendation?
    ) async throws -> (GuidanceResponseProtocol, String) {
        // For now, use the streaming approach and collect all content
        return try await generateGuidanceViaEdgeFunctionStreaming(
            situation: situation,
            childContext: childContext,
            keyInsights: keyInsights,
            apiKey: apiKey,
            activeFramework: activeFramework
        )
    }
    
    // MARK: - Direct API Implementation (Legacy)
    
    /// Generate guidance using legacy direct API approach
    private func generateGuidanceViaDirectAPI(
        situation: String,
        childContext: String?,
        keyInsights: String?,
        apiKey: String,
        activeFramework: FrameworkRecommendation?
    ) async throws -> (GuidanceResponseProtocol, String) {
        print("🔄 Using direct API for guidance generation (legacy)")
        
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
                    "current_situation": situation,
                    "active_foundation_tools": formatFrameworkForPrompt(framework)
                ]
                if let childContext = childContext, !childContext.isEmpty {
                    variables["child_context"] = childContext
                }
                if let keyInsights = keyInsights, !keyInsights.isEmpty {
                    variables["key_insights"] = keyInsights
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
                    "current_situation": situation
                ]
                if let childContext = childContext, !childContext.isEmpty {
                    variables["child_context"] = childContext
                }
                if let keyInsights = keyInsights, !keyInsights.isEmpty {
                    variables["key_insights"] = keyInsights
                }
                
                return (
                    "pmpt_68515280423c8193aaa00a07235b7cf206c51d869f9526ba",
                    version,
                    variables
                )
            }
        }()
        
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
    
    /// Parse guidance response from raw content
    private func parseGuidanceResponse(_ content: String) throws -> GuidanceResponseProtocol {
        guard let guidance = DynamicGuidanceParser.shared.parseWithFallback(content) else {
            throw GuidanceGenerationError.parsingError
        }
        
        return guidance
    }
    
    /// Format framework for prompt (legacy compatibility)
    private func formatFrameworkForPrompt(_ framework: FrameworkRecommendation) -> String {
        return """
        Framework: \(framework.frameworkName)
        Details: \(framework.notificationText)
        """
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
