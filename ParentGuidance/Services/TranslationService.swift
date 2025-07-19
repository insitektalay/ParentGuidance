//
//  TranslationService.swift
//  ParentGuidance
//
//  Created by alex kerss on 19/07/2025.
//

import Foundation

/// Service for translating content using OpenAI Prompts API
class TranslationService {
    static let shared = TranslationService()
    
    private init() {}
    
    // MARK: - Translation Configuration
    
    /// OpenAI Prompts API endpoint
    private let promptsAPIURL = "https://api.openai.com/v1/responses"
    
    /// Translation prompt template ID
    private let translationPromptID = "pmpt_687b28fd26208195b7bc8864d8d484090e772c7ac2176688"
    
    /// Prompt template version
    private let promptVersion = "1"
    
    // MARK: - Translation Methods
    
    /// Translate content to target language using OpenAI prompt template
    func translateContent(
        text: String,
        targetLanguage: String,
        apiKey: String
    ) async throws -> String {
        print("🌐 Translating content to \(targetLanguage)")
        print("📝 Content preview: \(text.prefix(100))...")
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranslationError.emptyText
        }
        
        guard !targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranslationError.invalidLanguage
        }
        
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranslationError.invalidAPIKey
        }
        
        let url = URL(string: promptsAPIURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build request body using your prompt template
        let requestBody: [String: Any] = [
            "prompt": [
                "id": translationPromptID,
                "version": promptVersion,
                "variables": [
                    "input_text": text,
                    "lang": targetLanguage
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            print("📡 Making translation API request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response for translation")
                throw TranslationError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                print("❌ Translation HTTP error: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ Translation error response: \(responseString)")
                }
                throw TranslationError.apiError(httpResponse.statusCode)
            }
            
            print("✅ Translation HTTP 200 response received")
            
            // Parse the response using the same structure as other prompt responses
            let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
            
            guard let firstOutput = promptResponse.output.first,
                  let firstContent = firstOutput.content.first else {
                print("❌ No content in translation response")
                throw TranslationError.noContent
            }
            
            let translatedText = firstContent.text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !translatedText.isEmpty else {
                print("❌ Empty translation result")
                throw TranslationError.emptyResult
            }
            
            print("✅ Translation completed successfully")
            print("📝 Translated preview: \(translatedText.prefix(100))...")
            
            return translatedText
            
        } catch {
            if error is TranslationError {
                throw error
            }
            print("❌ Translation request failed: \(error)")
            throw TranslationError.requestFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Batch Translation
    
    /// Translate multiple pieces of content in sequence
    func translateMultipleContent(
        texts: [String],
        targetLanguage: String,
        apiKey: String
    ) async throws -> [String] {
        print("🌐 Batch translating \(texts.count) items to \(targetLanguage)")
        
        var translations: [String] = []
        
        for (index, text) in texts.enumerated() {
            do {
                let translation = try await translateContent(
                    text: text,
                    targetLanguage: targetLanguage,
                    apiKey: apiKey
                )
                translations.append(translation)
                print("✅ Translated item \(index + 1)/\(texts.count)")
                
                // Add small delay to avoid rate limiting
                if index < texts.count - 1 {
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                }
                
            } catch {
                print("❌ Failed to translate item \(index + 1): \(error)")
                throw error
            }
        }
        
        print("✅ Batch translation completed: \(translations.count) items")
        return translations
    }
    
    // MARK: - Translation Validation
    
    /// Validate that a translation looks reasonable
    func validateTranslation(original: String, translated: String) -> TranslationValidation {
        let originalLength = original.count
        let translatedLength = translated.count
        
        // Check length ratio (translated should be within reasonable bounds)
        let lengthRatio = Double(translatedLength) / Double(originalLength)
        let isReasonableLength = lengthRatio >= 0.3 && lengthRatio <= 3.0
        
        // Check for obvious failures
        let appearsTranslated = !translated.lowercased().contains("i cannot translate") &&
                              !translated.lowercased().contains("unable to translate") &&
                              !translated.lowercased().contains("error")
        
        let isValid = isReasonableLength && appearsTranslated && !translated.isEmpty
        
        return TranslationValidation(
            isValid: isValid,
            lengthRatio: lengthRatio,
            originalLength: originalLength,
            translatedLength: translatedLength,
            warnings: isValid ? [] : generateValidationWarnings(lengthRatio: lengthRatio, appearsTranslated: appearsTranslated)
        )
    }
    
    private func generateValidationWarnings(lengthRatio: Double, appearsTranslated: Bool) -> [String] {
        var warnings: [String] = []
        
        if lengthRatio < 0.3 {
            warnings.append("Translation is much shorter than original")
        } else if lengthRatio > 3.0 {
            warnings.append("Translation is much longer than original")
        }
        
        if !appearsTranslated {
            warnings.append("Translation appears to contain error messages")
        }
        
        return warnings
    }
}

// MARK: - Supporting Models

/// Result of translation validation
struct TranslationValidation {
    let isValid: Bool
    let lengthRatio: Double
    let originalLength: Int
    let translatedLength: Int
    let warnings: [String]
}

/// Errors that can occur during translation
enum TranslationError: LocalizedError {
    case emptyText
    case invalidLanguage
    case invalidAPIKey
    case invalidResponse
    case apiError(Int)
    case noContent
    case emptyResult
    case requestFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "Cannot translate empty text"
        case .invalidLanguage:
            return "Invalid target language specified"
        case .invalidAPIKey:
            return "Invalid or missing API key"
        case .invalidResponse:
            return "Invalid response from translation API"
        case .apiError(let statusCode):
            return "Translation API error: HTTP \(statusCode)"
        case .noContent:
            return "No content returned from translation API"
        case .emptyResult:
            return "Translation result was empty"
        case .requestFailed(let message):
            return "Translation request failed: \(message)"
        }
    }
}