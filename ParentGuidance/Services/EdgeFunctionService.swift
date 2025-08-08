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
    
    /// Generate guidance using function calling (JSON response)
    func generateGuidanceWithFunctionCalling(
        situation: String,
        childContext: String? = nil,
        keyInsights: String? = nil,
        copingStrategies: String? = nil,
        activeFramework: FrameworkRecommendation? = nil,
        structureMode: String = "fixed",
        guidanceStyle: String = "Warm Practical",
        situationType: SituationType = .imJustWondering,
        apiKey: String,
        regenRunId: UUID? = nil,
        experimentRunId: UUID? = nil
    ) async throws -> EdgeFunctionGuidanceResponse {
        print("🔄 [EdgeFunction] Generating guidance via Edge Function (function calling)")
        print("   → Operation: guidance")
        print("   → Has Framework: \(activeFramework != nil)")
        print("   → Structure Mode: \(structureMode)")
        print("   → Guidance Style: \(guidanceStyle)")
        print("   → Situation Type: \(situationType.rawValue)")
        print("   → Function Calling: true")
        
        var variables: [String: Any] = [
            "current_situation": situation,
            "structure_mode": structureMode,
            "guidance_style": guidanceStyle,
            "situation_type": situationType.rawValue
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
        
        if let framework = activeFramework {
            let formattedFramework = formatFrameworkForRequest(framework)
            variables["active_foundation_tools"] = formattedFramework
            print("🔍 FRAMEWORK FORMATTING CHECK:")
            print("🔍   Original name: '\(framework.frameworkName)'")
            print("🔍   Formatted value: '\(formattedFramework)'")
            print("🔍   Contains notification text: \(formattedFramework.contains(framework.notificationText))")
        }
        
        // Log all variables being sent to edge function
        print("📤 ===== EDGE FUNCTION REQUEST VARIABLES =====")
        print("📤 All variables being sent:")
        for (key, value) in variables {
            print("📤   \(key): \(value)")
        }
        print("📤 ===============================================")
        
        let startedAt = Date()
        let result = try await callEdgeFunction(
            operation: "guidance",
            variables: variables,
            apiKey: apiKey,
            customBody: [
                "operation": "guidance",
                "variables": variables,
                "apiKey": apiKey,
                "useFunctionCalling": true
            ]
        )
        let duration = Date().timeIntervalSince(startedAt)
        await RunLogService.shared.log(
            regenRunId: regenRunId,
            experimentRunId: experimentRunId,
            level: .info,
            message: "edge.guidance(function_calling) ok duration_ms=\(Int(duration*1000))"
        )
        
        // Parse the response
        guard let success = result["success"] as? Bool, success,
              let format = result["format"] as? String, format == "structured",
              let data = result["data"] as? [String: Any] else {
            let errorMessage = result["error"] as? String ?? "Unknown error"
            print("❌ [EdgeFunction] Function calling guidance generation failed: \(errorMessage)")
            throw EdgeFunctionError.invalidResponse
        }
        
        // Convert to our response format
        let jsonData = try JSONSerialization.data(withJSONObject: result)
        let response = try JSONDecoder().decode(EdgeFunctionGuidanceResponse.self, from: jsonData)
        
        print("✅ [EdgeFunction] Function calling guidance generation completed")
        print("✅ Title: \(response.data.title)")
        print("✅ Sections: \(response.data.sections.count)")
        
        return response
    }

    /// Stream guidance generation with optional framework
    func streamGuidance(
        situation: String,
        childContext: String? = nil,
        keyInsights: String? = nil,
        copingStrategies: String? = nil,
        activeFramework: FrameworkRecommendation? = nil,
        structureMode: String = "fixed",
        guidanceStyle: String = "Warm Practical",
        situationType: SituationType = .imJustWondering,
        apiKey: String,
        regenRunId: UUID? = nil,
        experimentRunId: UUID? = nil
    ) async throws -> AsyncThrowingStream<String, Error> {
        print("🔄 [EdgeFunction] Streaming guidance via Edge Function")
        print("   → Operation: guidance")
        print("   → Has Framework: \(activeFramework != nil)")
        print("   → Structure Mode: \(structureMode)")
        print("   → Guidance Style: \(guidanceStyle)")
        print("   → Situation Type: \(situationType.rawValue)")
        
        var variables: [String: Any] = [
            "current_situation": situation,
            "structure_mode": structureMode,
            "guidance_style": guidanceStyle,
            "situation_type": situationType.rawValue
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
        
        if let framework = activeFramework {
            let formattedFramework = formatFrameworkForRequest(framework)
            variables["active_foundation_tools"] = formattedFramework
            print("🔍 FRAMEWORK FORMATTING CHECK:")
            print("🔍   Original name: '\(framework.frameworkName)'")
            print("🔍   Formatted value: '\(formattedFramework)'")
            print("🔍   Contains notification text: \(formattedFramework.contains(framework.notificationText))")
        }
        
        // Log all variables being sent to edge function
        print("📤 ===== EDGE FUNCTION REQUEST VARIABLES =====")
        print("📤 All variables being sent:")
        for (key, value) in variables {
            print("📤   \(key): \(value)")
        }
        print("📤 ===============================================")
        
        return try await streamRequest(
            operation: "guidance",
            variables: variables,
            apiKey: apiKey,
            regenRunId: regenRunId,
            experimentRunId: experimentRunId
        )
    }
    
    /// Analyze a situation for category and incident type (non-streaming)
    func analyzeSituation(
        situationText: String,
        apiKey: String,
        regenRunId: UUID? = nil,
        experimentRunId: UUID? = nil
    ) async throws -> (category: String, isIncident: Bool) {
        print("🔄 [EdgeFunction] Analyzing situation via Edge Function")
        print("   → Operation: analyze")
        
        let startedAt = Date()
        let response = try await jsonRequest(
            operation: "analyze",
            variables: ["situation_text": situationText],
            apiKey: apiKey,
            regenRunId: regenRunId,
            experimentRunId: experimentRunId
        )
        let duration = Date().timeIntervalSince(startedAt)
        await RunLogService.shared.log(regenRunId: regenRunId, experimentRunId: experimentRunId, level: .info, message: "edge.analyze ok duration_ms=\(Int(duration*1000))")
        
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
        apiKey: String,
        regenRunId: UUID? = nil,
        experimentRunId: UUID? = nil
    ) async throws -> String {
        print("🔄 [EdgeFunction] Generating framework via Edge Function")
        print("   → Operation: framework")
        
        return try await jsonRequest(
            operation: "framework",
            variables: ["recent_situations": recentSituations],
            apiKey: apiKey,
            regenRunId: regenRunId,
            experimentRunId: experimentRunId
        )
    }
    
    /// Extract contextual insights (non-streaming)
    func extractContext(
        situationText: String,
        extractionType: String = "general",
        apiKey: String,
        regenRunId: UUID? = nil,
        experimentRunId: UUID? = nil
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
            apiKey: apiKey,
            regenRunId: regenRunId,
            experimentRunId: experimentRunId
        )
    }
    
    /// Extract coping strategies (non-streaming)
    func extractCopingStrategies(
        situationText: String,
        apiKey: String,
        regenRunId: UUID? = nil,
        experimentRunId: UUID? = nil
    ) async throws -> String {
        print("🔄 [EdgeFunction] Extracting coping strategies via Edge Function")
        print("   → Operation: coping_strategies")
        
        return try await jsonRequest(
            operation: "coping_strategies",
            variables: [
                "longtext": situationText
            ],
            apiKey: apiKey,
            regenRunId: regenRunId,
            experimentRunId: experimentRunId
        )
    }
    
    /// Stream translation of guidance content
    func streamTranslation(
        guidanceContent: String,
        targetLanguage: String,
        apiKey: String,
        regenRunId: UUID? = nil,
        experimentRunId: UUID? = nil
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
            apiKey: apiKey,
            regenRunId: regenRunId,
            experimentRunId: experimentRunId
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
    
    /// Extract overall recommendation from guidance content (non-streaming)
    func extractOverallRecommendation(
        guidanceContent: String,
        apiKey: String,
        regenRunId: UUID? = nil,
        experimentRunId: UUID? = nil
    ) async throws -> String {
        print("🔄 [EdgeFunction] ===== OVERALL RECOMMENDATION EXTRACTION =====")
        print("   → Operation: extract_overall_recommendation")
        print("   → Source content length: \(guidanceContent.count) characters")
        print("   → Source content preview: \(String(guidanceContent.prefix(300)))...")
        print("   → Edge Function URL: \(baseURL)")
        print("   → Using API key: \(apiKey.prefix(10))...")
        
        do {
            let startedAt = Date()
            let result = try await jsonRequest(
                operation: "extract_overall_recommendation",
                variables: ["source_text": guidanceContent],
                apiKey: apiKey,
                regenRunId: regenRunId,
                experimentRunId: experimentRunId
            )
            let duration = Date().timeIntervalSince(startedAt)
            await RunLogService.shared.log(regenRunId: regenRunId, experimentRunId: experimentRunId, level: .info, message: "edge.extract_overall_recommendation ok duration_ms=\(Int(duration*1000))")
            print("✅ [EdgeFunction] Recommendation extraction successful")
            print("   → Raw response: \(result)")
            print("🔄 [EdgeFunction] ========================================")
            return result
        } catch {
            print("❌ [EdgeFunction] Recommendation extraction FAILED: \(error)")
            print("   → Error details: \(error.localizedDescription)")
            print("🔄 [EdgeFunction] ========================================")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    /// Make a streaming request to the edge function
    private func streamRequest(
        operation: String,
        variables: [String: Any],
        apiKey: String,
        regenRunId: UUID? = nil,
        experimentRunId: UUID? = nil
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
        
        let startedAt = Date()
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
                    let duration = Date().timeIntervalSince(startedAt)
                    await RunLogService.shared.log(regenRunId: regenRunId, experimentRunId: experimentRunId, level: .info, message: "edge.\(operation) stream completed duration_ms=\(Int(duration*1000))")
                } catch {
                    continuation.finish(throwing: EdgeFunctionError.streamingError(error.localizedDescription))
                    await RunLogService.shared.log(regenRunId: regenRunId, experimentRunId: experimentRunId, level: .error, message: "edge.\(operation) stream error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Make a non-streaming JSON request to the edge function
    private func jsonRequest(
        operation: String,
        variables: [String: Any],
        apiKey: String,
        regenRunId: UUID? = nil,
        experimentRunId: UUID? = nil
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
        
        let startedAt = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            await RunLogService.shared.log(regenRunId: regenRunId, experimentRunId: experimentRunId, level: .error, message: "edge.\(operation) httpError status=\(status)")
            throw EdgeFunctionError.httpError(statusCode: status)
        }
        
        // Parse the response
        
        // First, try to convert raw data to string for debugging
        if let rawString = String(data: data, encoding: .utf8) {
        } else {
            print("❌ [EdgeFunction] Raw response data is not valid UTF-8!")
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            if let success = json["success"] as? Bool {
                
                if success, let responseData = json["data"] as? String {
                    print("✅ [EdgeFunction] Response data extracted successfully")
                    
                    // Validate that the response data is valid UTF-8
                    if responseData.data(using: .utf8) != nil {
                        print("✅ [EdgeFunction] Response data is valid UTF-8")
                        let duration = Date().timeIntervalSince(startedAt)
                        await RunLogService.shared.log(regenRunId: regenRunId, experimentRunId: experimentRunId, level: .info, message: "edge.\(operation) ok duration_ms=\(Int(duration*1000)) size=\(responseData.count)")
                        return responseData
                    } else {
                        print("❌ [EdgeFunction] Response data contains invalid UTF-8 characters!")
                        await RunLogService.shared.log(regenRunId: regenRunId, experimentRunId: experimentRunId, level: .error, message: "edge.\(operation) invalidResponse utf8")
                        throw EdgeFunctionError.invalidResponse
                    }
                } else {
                    print("❌ [EdgeFunction] Success=false or missing data field")
                    if let errorMessage = json["error"] as? String {
                        print("❌ [EdgeFunction] Error message: \(errorMessage)")
                        await RunLogService.shared.log(regenRunId: regenRunId, experimentRunId: experimentRunId, level: .error, message: "edge.\(operation) error: \(errorMessage)")
                    }
                }
            } else {
                print("❌ [EdgeFunction] Missing or invalid success field")
                await RunLogService.shared.log(regenRunId: regenRunId, experimentRunId: experimentRunId, level: .error, message: "edge.\(operation) invalidResponse missing success")
            }
        } else {
            print("❌ [EdgeFunction] JSON parsing failed")
            await RunLogService.shared.log(regenRunId: regenRunId, experimentRunId: experimentRunId, level: .error, message: "edge.\(operation) invalidResponse json parse failed")
        }
        
        throw EdgeFunctionError.invalidResponse
    }
    
    /// Format framework for the request
    private func formatFrameworkForRequest(_ framework: FrameworkRecommendation) -> String {
        return framework.frameworkName
    }
    
    /// Make a custom Edge Function call with custom body parameters (for audio transcription)
    func callEdgeFunction(
        operation: String,
        variables: [String: Any],
        apiKey: String,
        customBody: [String: Any]? = nil
    ) async throws -> [String: Any] {
        print("🔄 [EdgeFunction] Calling Edge Function with custom body")
        print("   → Operation: \(operation)")
        
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(try await SupabaseManager.shared.client.auth.session.accessToken)", 
                        forHTTPHeaderField: "Authorization")
        
        // Use custom body if provided, otherwise create standard body
        let body = customBody ?? [
            "operation": operation,
            "variables": variables,
            "apiKey": apiKey
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response status
        if let httpResponse = response as? HTTPURLResponse {
            print("📊 [EdgeFunction] Response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                print("❌ [EdgeFunction] HTTP error: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ [EdgeFunction] Error response: \(responseString)")
                }
                throw EdgeFunctionError.httpError(statusCode: httpResponse.statusCode)
            }
        }
        
        // Parse JSON response
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ [EdgeFunction] Invalid JSON response")
            throw EdgeFunctionError.invalidResponse
        }
        
        print("✅ [EdgeFunction] Response received successfully")
        return jsonResponse
    }
    
    // MARK: - Embedding and Deduplication Methods
    
    /// Generate vector embedding with multilingual support
    func generateEmbedding(
        text: String,
        apiKey: String,
        sourceLanguage: String? = nil
    ) async throws -> EmbeddingData {
        print("🔄 [EdgeFunction] Generating embedding via Edge Function")
        print("   → Text length: \(text.count) characters")
        print("   → Source language: \(sourceLanguage ?? "auto-detect")")
        
        let variables: [String: Any] = [
            "text": text,
            "source_language": sourceLanguage as Any
        ]
        
        let result = try await callEdgeFunction(
            operation: "generate_embedding",
            variables: variables,
            apiKey: apiKey
        )
        
        // Parse the response
        guard let success = result["success"] as? Bool, success,
              let data = result["data"] as? [String: Any] else {
            let errorMessage = result["error"] as? String ?? "Unknown error"
            print("❌ [EdgeFunction] Embedding generation failed: \(errorMessage)")
            throw EdgeFunctionError.invalidResponse
        }
        
        // Parse embedding data from response
        guard let embedding = data["embedding"] as? [Float],
              let detectedLanguage = data["detectedLanguage"] as? String,
              let wasTranslated = data["wasTranslated"] as? Bool,
              let originalText = data["originalText"] as? String,
              let embeddedText = data["embeddedText"] as? String,
              let model = data["model"] as? String,
              let dimension = data["dimension"] as? Int,
              let processingTimeMs = data["processingTimeMs"] as? Int else {
            print("❌ [EdgeFunction] Invalid embedding data format")
            throw EdgeFunctionError.invalidResponse
        }
        
        let embeddingData = EmbeddingData(
            embedding: embedding,
            detectedLanguage: detectedLanguage,
            wasTranslated: wasTranslated,
            originalText: originalText,
            embeddedText: embeddedText,
            model: model,
            dimension: dimension,
            processingTimeMs: processingTimeMs
        )
        
        print("✅ [EdgeFunction] Embedding generated successfully")
        print("   → Language: \(detectedLanguage), Translated: \(wasTranslated)")
        print("   → Dimension: \(dimension), Processing time: \(processingTimeMs)ms")
        
        return embeddingData
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
        print("🔄 [EdgeFunction] Checking similarity via Edge Function")
        print("   → Table: \(tableName), Category: \(category)")
        print("   → Threshold: \(similarityThreshold ?? 0.0)")
        
        let variables: [String: Any] = [
            "embedding": embedding,
            "family_id": familyId,
            "category": category,
            "table_name": tableName,
            "subcategory": subcategory as Any,
            "similarity_threshold": similarityThreshold as Any
        ]
        
        let result = try await callEdgeFunction(
            operation: "check_similarity",
            variables: variables,
            apiKey: apiKey
        )
        
        // Parse the response
        guard let success = result["success"] as? Bool, success,
              let data = result["data"] as? [String: Any] else {
            let errorMessage = result["error"] as? String ?? "Unknown error"
            print("❌ [EdgeFunction] Similarity check failed: \(errorMessage)")
            throw EdgeFunctionError.invalidResponse
        }
        
        // Parse similarity data from response
        guard let similarInsightsData = data["similarInsights"] as? [[String: Any]],
              let recommendedAction = data["recommendedAction"] as? String,
              let deduplicationPolicy = data["deduplicationPolicy"] as? String,
              let highestSimilarity = data["highestSimilarity"] as? Float,
              let searchTimeMs = data["searchTimeMs"] as? Int,
              let threshold = data["threshold"] as? Float,
              let totalFound = data["totalFound"] as? Int else {
            print("❌ [EdgeFunction] Invalid similarity data format")
            throw EdgeFunctionError.invalidResponse
        }
        
        // Parse similar insights
        var similarInsights: [SimilarInsight] = []
        for insightData in similarInsightsData {
            guard let id = insightData["id"] as? String,
                  let content = insightData["content"] as? String,
                  let category = insightData["category"] as? String,
                  let similarityScore = insightData["similarity_score"] as? Float,
                  let wasTranslated = insightData["was_translated"] as? Bool,
                  let createdAt = insightData["created_at"] as? String else {
                continue
            }
            
            let similarInsight = SimilarInsight(
                id: id,
                content: content,
                category: category,
                similarityScore: similarityScore,
                wasTranslated: wasTranslated,
                createdAt: createdAt
            )
            similarInsights.append(similarInsight)
        }
        
        let similarityData = SimilarityData(
            similarInsights: similarInsights,
            recommendedAction: recommendedAction,
            deduplicationPolicy: deduplicationPolicy,
            highestSimilarity: highestSimilarity,
            searchTimeMs: searchTimeMs,
            threshold: threshold,
            totalFound: totalFound
        )
        
        print("✅ [EdgeFunction] Similarity check completed")
        print("   → Found: \(totalFound), Action: \(recommendedAction)")
        print("   → Highest similarity: \(highestSimilarity)")
        
        return similarityData
    }
    
    // MARK: - Which Insights Matter
    
    /// Select which existing insights are relevant to a guidance text
    func selectWhichInsightsMatter(
        guidanceText: String,
        insightsList: String,
        apiKey: String
    ) async throws -> String {
        print("🎯 [EdgeFunction] Selecting relevant insights")
        print("   → Guidance text length: \(guidanceText.count)")
        print("   → Insights list length: \(insightsList.count)")
        
        let requestBody: [String: Any] = [
            "operation": "which_insights_matter",
            "variables": [
                "GuidanceText": guidanceText,
                "InsightList": insightsList
            ],
            "apiKey": apiKey
        ]
        
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(try await SupabaseManager.shared.client.auth.session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EdgeFunctionError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [EdgeFunction] Which insights matter failed: \(httpResponse.statusCode) - \(errorMessage)")
            throw EdgeFunctionError.httpError(statusCode: httpResponse.statusCode)
        }
        
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = jsonResponse["content"] as? String else {
            throw EdgeFunctionError.invalidResponse
        }
        
        print("✅ [EdgeFunction] Relevant insights selection completed")
        return content
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