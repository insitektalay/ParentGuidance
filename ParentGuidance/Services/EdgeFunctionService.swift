//
//  EdgeFunctionService.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/07/2025.
//

import Foundation

/// Service for communicating with Supabase Edge Functions
class EdgeFunctionService {
    static let shared = EdgeFunctionService()
    
    private let baseURL: String
    
    private init() {
        // Get the Supabase URL from SupabaseManager
        let supabaseURL = "https://xxrbavrptjexshgkpzon.supabase.co"
        self.baseURL = "\(supabaseURL)/functions/v1/guidance"
    }
    
    // MARK: - Public Methods
    
    /// Stream guidance generation with optional framework
    func streamGuidance(
        situation: String,
        childContext: String? = nil,
        keyInsights: String? = nil,
        activeFramework: FrameworkRecommendation? = nil,
        structureMode: String = "fixed",
        situationType: SituationType = .imJustWondering,
        apiKey: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        print("🔄 [EdgeFunction] Streaming guidance via Edge Function")
        print("   → Operation: guidance")
        print("   → Has Framework: \(activeFramework != nil)")
        print("   → Structure Mode: \(structureMode)")
        print("   → Situation Type: \(situationType.rawValue)")
        
        var variables: [String: Any] = [
            "current_situation": situation,
            "structure_mode": structureMode,
            "situation_type": situationType.rawValue
        ]
        
        if let childContext = childContext, !childContext.isEmpty {
            variables["child_context"] = childContext
        }
        
        if let keyInsights = keyInsights, !keyInsights.isEmpty {
            variables["key_insights"] = keyInsights
        }
        
        if let framework = activeFramework {
            variables["active_foundation_tools"] = formatFrameworkForRequest(framework)
        }
        
        return try await streamRequest(
            operation: "guidance",
            variables: variables,
            apiKey: apiKey
        )
    }
    
    /// Analyze a situation for category and incident type (non-streaming)
    func analyzeSituation(
        situationText: String,
        apiKey: String
    ) async throws -> (category: String, isIncident: Bool) {
        print("🔄 [EdgeFunction] Analyzing situation via Edge Function")
        print("   → Operation: analyze")
        
        let response = try await jsonRequest(
            operation: "analyze",
            variables: ["situation_text": situationText],
            apiKey: apiKey
        )
        
        print("🔍 [DEBUG] Analyze response received: '\(response)'")
        print("🔍 [DEBUG] Response length: \(response.count)")
        
        // Parse the JSON response
        if let data = response.data(using: .utf8) {
            print("🔍 [DEBUG] Data conversion successful")
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("🔍 [DEBUG] JSON parsing successful: \(json)")
                if let category = json["category"] as? String {
                    print("🔍 [DEBUG] Category found: '\(category)'")
                    if let isIncident = json["isIncident"] as? Bool {
                        print("🔍 [DEBUG] isIncident found: \(isIncident)")
                        print("✅ [DEBUG] Analyze parsing successful")
                        return (category, isIncident)
                    } else {
                        print("❌ [DEBUG] isIncident not found or wrong type")
                    }
                } else {
                    print("❌ [DEBUG] Category not found or wrong type")
                }
            } else {
                print("❌ [DEBUG] JSON parsing failed")
            }
        } else {
            print("❌ [DEBUG] Data conversion failed")
        }
        
        print("❌ [DEBUG] Throwing invalidResponse")
        throw EdgeFunctionError.invalidResponse
    }
    
    /// Generate framework recommendations (non-streaming)
    func generateFramework(
        recentSituations: String,
        apiKey: String
    ) async throws -> String {
        print("🔄 [EdgeFunction] Generating framework via Edge Function")
        print("   → Operation: framework")
        
        return try await jsonRequest(
            operation: "framework",
            variables: ["recent_situations": recentSituations],
            apiKey: apiKey
        )
    }
    
    /// Extract contextual insights (non-streaming)
    func extractContext(
        situationText: String,
        extractionType: String = "general",
        apiKey: String
    ) async throws -> String {
        print("🔄 [EdgeFunction] Extracting context via Edge Function")
        print("   → Operation: context")
        print("   → Extraction Type: \(extractionType)")
        
        return try await jsonRequest(
            operation: "context",
            variables: [
                "situation_text": situationText,
                "extraction_type": extractionType
            ],
            apiKey: apiKey
        )
    }
    
    /// Stream translation of guidance content
    func streamTranslation(
        guidanceContent: String,
        targetLanguage: String,
        apiKey: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        print("🔄 [EdgeFunction] Streaming translation via Edge Function")
        print("   → Operation: translate")
        print("   → Target Language: \(targetLanguage)")
        
        return try await streamRequest(
            operation: "translate",
            variables: [
                "guidance_content": guidanceContent,
                "target_language": targetLanguage
            ],
            apiKey: apiKey
        )
    }
    
    /// Generate psychologist note content (non-streaming)
    func generatePsychologistNote(
        noteType: PsychologistNoteType,
        sourceData: String,
        apiKey: String
    ) async throws -> String {
        print("🔄 [EdgeFunction] Generating psychologist note via Edge Function")
        print("   → Operation: \(noteType.promptOperation)")
        print("   → Source data length: \(sourceData.count) characters")
        
        let variableKey = noteType == .context ? 
            "structured_context_data_over_time" : 
            "bullet_point_pattern_data_over_time"
        
        return try await jsonRequest(
            operation: noteType.promptOperation,
            variables: [variableKey: sourceData],
            apiKey: apiKey
        )
    }
    
    // MARK: - Private Methods
    
    /// Make a streaming request to the edge function
    private func streamRequest(
        operation: String,
        variables: [String: Any],
        apiKey: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(try await SupabaseManager.shared.client.auth.session.accessToken)", 
                        forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "operation": operation,
            "variables": variables,
            "apiKey": apiKey
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw EdgeFunctionError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        // Handle SSE format
                        if line.hasPrefix("data: ") {
                            let data = String(line.dropFirst(6))
                            
                            if data == "[DONE]" {
                                continuation.finish()
                                return
                            }
                            
                            // Parse the data stream format from Vercel AI SDK
                            if let jsonData = data.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                                // Extract text from the Vercel AI SDK format
                                for item in json {
                                    if let type = item["type"] as? String,
                                       type == "text",
                                       let text = item["value"] as? String {
                                        continuation.yield(text)
                                    }
                                }
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Make a non-streaming JSON request to the edge function
    private func jsonRequest(
        operation: String,
        variables: [String: Any],
        apiKey: String
    ) async throws -> String {
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(try await SupabaseManager.shared.client.auth.session.accessToken)", 
                        forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "operation": operation,
            "variables": variables,
            "apiKey": apiKey
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw EdgeFunctionError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        // Parse the response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let success = json["success"] as? Bool,
           success,
           let responseData = json["data"] as? String {
            return responseData
        }
        
        throw EdgeFunctionError.invalidResponse
    }
    
    /// Format framework for the request
    private func formatFrameworkForRequest(_ framework: FrameworkRecommendation) -> String {
        var parts: [String] = []
        
        parts.append("Framework: \(framework.frameworkName)")
        
        if !framework.notificationText.isEmpty {
            parts.append("Description: \(framework.notificationText)")
        }
        
        // Add framework type description if available
        if let frameworkType = framework.frameworkType {
            parts.append("Type Description: \(frameworkType.description)")
        }
        
        return parts.joined(separator: "\n")
    }
}

// MARK: - Error Types

enum EdgeFunctionError: LocalizedError {
    case httpError(statusCode: Int)
    case invalidResponse
    case streamingError(String)
    
    var errorDescription: String? {
        switch self {
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .invalidResponse:
            return "Invalid response format from edge function"
        case .streamingError(let message):
            return "Streaming error: \(message)"
        }
    }
}