//
//  FrameworkGenerationService.swift
//  ParentGuidance
//
//  Created by alex kerss on 07/07/2025.
//

import Foundation

// MARK: - Framework Generation Errors

enum FrameworkGenerationError: Error, LocalizedError {
    case insufficientData
    case noGuidanceFound
    case apiError(String)
    case parsingError
    case invalidResponse
    case networkError
    case invalidAPIKey
    
    var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "Please select at least 2 situations to generate a meaningful framework recommendation"
        case .noGuidanceFound:
            return "No guidance data found for the selected situations"
        case .apiError(let message):
            return "API Error: \(message)"
        case .parsingError:
            return "Failed to parse the framework recommendation from the response"
        case .invalidResponse:
            return "The generated framework recommendation is invalid"
        case .networkError:
            return "Network connection error. Please check your internet connection"
        case .invalidAPIKey:
            return "Invalid API key. Please check your OpenAI API configuration"
        }
    }
}

// MARK: - Framework Generation Service

class FrameworkGenerationService {
    static let shared = FrameworkGenerationService()
    
    // OpenAI API Configuration
    private let openAIBaseURL = "https://api.openai.com"
    private let promptID = "pmpt_68511f82ba448193a1af0dc01215706f0d3d3fe75d5db0f1" // Version 3
    
    private init() {}
    
    // MARK: - Main Generation Method
    
    /// Generate a framework recommendation from selected situations
    func generateFramework(
        from selectedSituations: [Situation],
        apiKey: String
    ) async throws -> FrameworkRecommendation {
        print("🚀 Starting framework generation with \(selectedSituations.count) situations")
        
        // Step 1: Validate input
        guard validateSituationInput(situations: selectedSituations) else {
            throw FrameworkGenerationError.insufficientData
        }
        
        // Step 2: Extract situation data from guidance records
        print("📊 Extracting situation data from guidance records...")
        let situationSummary = try await extractSituationData(from: selectedSituations)
        
        guard !situationSummary.isEmpty else {
            throw FrameworkGenerationError.noGuidanceFound
        }
        
        print("✅ Extracted \(situationSummary.count) characters of situation data")
        
        // Step 3: Call OpenAI API
        print("📡 Calling OpenAI API with prompt ID: \(promptID)")
        let rawResponse = try await callOpenAIAPI(
            situationSummary: situationSummary,
            apiKey: apiKey
        )
        
        // Step 4: Parse and validate response
        print("🔍 Parsing framework recommendation from response...")
        guard let frameworkRecommendation = parseFrameworkResponse(rawResponse) else {
            throw FrameworkGenerationError.parsingError
        }
        
        guard validateFrameworkResponse(frameworkRecommendation) else {
            throw FrameworkGenerationError.invalidResponse
        }
        
        print("✅ Successfully generated framework: \(frameworkRecommendation.frameworkName)")
        return frameworkRecommendation
    }
    
    // MARK: - Data Extraction Methods
    
    /// Extract situation data from guidance records
    private func extractSituationData(from situations: [Situation]) async throws -> String {
        var allSituationTexts: [String] = []
        
        for situation in situations {
            print("📋 Processing situation: \(situation.title)")
            
            // Get guidance for this situation
            let guidance = try await ConversationService.shared.getGuidanceForSituation(
                situationId: situation.id
            )
            
            // Extract [SITUATION] sections from guidance
            let situationSections = extractSituationSections(from: guidance)
            allSituationTexts.append(contentsOf: situationSections)
        }
        
        // Combine all situation texts
        let combinedText = allSituationTexts.joined(separator: "\n\n")
        print("📝 Combined situation data: \(combinedText.prefix(100))...")
        
        return combinedText
    }
    
    /// Extract [SITUATION] sections from guidance content
    private func extractSituationSections(from guidance: [Guidance]) -> [String] {
        var situationSections: [String] = []
        
        for guidanceItem in guidance {
            let content = guidanceItem.content
            
            // Look for [SITUATION] section using regex
            let pattern = #"\[SITUATION\](.*?)(?=\[|$)"#
            
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
                let range = NSRange(location: 0, length: content.count)
                
                let matches = regex.matches(in: content, options: [], range: range)
                for match in matches {
                    if let situationRange = Range(match.range(at: 1), in: content) {
                        let situationText = String(content[situationRange])
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !situationText.isEmpty {
                            situationSections.append(situationText)
                            print("✂️ Extracted situation section: \(situationText.prefix(50))...")
                        }
                    }
                }
            } catch {
                print("❌ Regex error extracting situation: \(error)")
            }
        }
        
        return situationSections
    }
    
    /// Format situations for API consumption
    private func formatSituationsForAPI(situations: [Situation]) -> String {
        let formattedSituations = situations.enumerated().map { index, situation in
            return "Situation \(index + 1): \(situation.title)\nDescription: \(situation.description)"
        }
        
        return formattedSituations.joined(separator: "\n\n")
    }
    
    /// Validate situation input
    private func validateSituationInput(situations: [Situation]) -> Bool {
        return situations.count >= 2 && situations.count <= 10
    }
    
    // MARK: - OpenAI API Integration
    
    /// Call OpenAI Prompts API with situation summary
    private func callOpenAIAPI(
        situationSummary: String,
        apiKey: String
    ) async throws -> String {
        
        let url = URL(string: "\(openAIBaseURL)/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Request body for Prompts API (matching working format from NewSituationView)
        let requestBody: [String: Any] = [
            "prompt": [
                "id": promptID,
                "version": "3",
                "variables": [
                    "situation_summary": situationSummary
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw FrameworkGenerationError.apiError("Failed to serialize request: \(error)")
        }
        
        print("📡 Making API request to: \(url)")
        print("🔧 Request body preview: \(String(describing: requestBody))")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 API Response status: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 401 {
                        throw FrameworkGenerationError.invalidAPIKey
                    }
                    
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw FrameworkGenerationError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
                }
            }
            
            return try handleAPIResponse(data)
            
        } catch {
            if error is FrameworkGenerationError {
                throw error
            }
            
            print("❌ Network error: \(error)")
            throw FrameworkGenerationError.networkError
        }
    }
    
    /// Handle and parse OpenAI API response
    private func handleAPIResponse(_ data: Data) throws -> String {
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw FrameworkGenerationError.apiError("Invalid response encoding")
        }
        
        print("📦 Raw API response: \(responseString.prefix(200))...")
        
        // Parse JSON response using the same format as NewSituationView
        do {
            let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
            print("✅ JSON decoded successfully")
            print("🔍 Prompt response id: \(promptResponse.id)")
            print("🔍 Output count: \(promptResponse.output.count)")
            
            guard let firstOutput = promptResponse.output.first,
                  let firstContent = firstOutput.content.first else {
                print("❌ No content in response")
                throw FrameworkGenerationError.apiError("No content in response")
            }
            
            let content = firstContent.text
            print("📝 Content received: \(content.prefix(100))...")
            
            return content
            
        } catch {
            print("❌ JSON parsing error: \(error)")
            throw FrameworkGenerationError.apiError("Failed to parse response JSON: \(error)")
        }
    }
    
    // MARK: - Response Processing
    
    /// Parse framework recommendation from OpenAI response
    private func parseFrameworkResponse(_ rawResponse: String) -> FrameworkRecommendation? {
        print("🔍 Parsing framework from response...")
        
        let apiResponse = FrameworkAPIResponse(rawContent: rawResponse)
        return apiResponse.parseFramework()
    }
    
    /// Validate the generated framework recommendation
    private func validateFrameworkResponse(_ recommendation: FrameworkRecommendation) -> Bool {
        let isValid = recommendation.isValid
        
        if !isValid {
            print("❌ Framework validation failed:")
            print("   - Framework name: '\(recommendation.frameworkName)'")
            print("   - Notification length: \(recommendation.notificationText.count)")
        }
        
        return isValid
    }
}

// MARK: - Convenience Methods

extension FrameworkGenerationService {
    /// Generate framework from situation IDs (convenience method)
    func generateFramework(
        from situationIds: [String],
        familyId: String,
        apiKey: String
    ) async throws -> FrameworkRecommendation {
        
        // Get all situations for the family
        let allSituations = try await ConversationService.shared.getAllSituations(familyId: familyId)
        
        // Filter to selected situations
        let selectedSituations = allSituations.filter { situationIds.contains($0.id) }
        
        guard selectedSituations.count == situationIds.count else {
            throw FrameworkGenerationError.insufficientData
        }
        
        return try await generateFramework(from: selectedSituations, apiKey: apiKey)
    }
    
    /// Validate API key format
    func validateAPIKey(_ apiKey: String) -> Bool {
        // Basic OpenAI API key validation
        return apiKey.hasPrefix("sk-") && apiKey.count > 20
    }
    
    /// Get supported framework types
    func getSupportedFrameworkTypes() -> [FrameworkType] {
        return FrameworkType.allCases
    }
}