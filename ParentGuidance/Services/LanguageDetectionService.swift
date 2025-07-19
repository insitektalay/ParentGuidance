//
//  LanguageDetectionService.swift
//  ParentGuidance
//
//  Created by alex kerss on 19/07/2025.
//

import Foundation
import NaturalLanguage

/// Service for detecting and managing language content
class LanguageDetectionService {
    static let shared = LanguageDetectionService()
    
    private init() {}
    
    // MARK: - Language Detection
    
    /// Detect the language of given text using NaturalLanguage framework
    func detectLanguage(from text: String) -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "en" // Default to English for empty text
        }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        // Get the most likely language
        guard let language = recognizer.dominantLanguage else {
            print("⚠️ Could not detect language, defaulting to English")
            return "en"
        }
        
        // Convert to ISO language code
        let languageCode = language.rawValue
        print("🌍 Detected language: \(languageCode) for text: \(text.prefix(50))...")
        
        return languageCode
    }
    
    /// Get confidence score for language detection
    func getLanguageConfidence(from text: String) -> [String: Double] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ["en": 1.0]
        }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        // Get language hypotheses with confidence scores
        let hypotheses = recognizer.languageHypotheses(withMaximum: 3)
        
        // Convert to string keys
        var result: [String: Double] = [:]
        for (language, confidence) in hypotheses {
            result[language.rawValue] = confidence
        }
        
        return result.isEmpty ? ["en": 1.0] : result
    }
    
    // MARK: - Language Validation
    
    /// Check if a language code is supported
    func isSupportedLanguage(_ languageCode: String) -> Bool {
        let supportedLanguages = getSupportedLanguages()
        return supportedLanguages.contains(languageCode)
    }
    
    /// Get list of supported languages for the app
    func getSupportedLanguages() -> [String] {
        return [
            "en", // English
            "es", // Spanish
            "fr", // French
            "de", // German
            "it", // Italian
            "pt", // Portuguese
            "ru", // Russian
            "zh", // Chinese
            "ja", // Japanese
            "ko", // Korean
            "ar", // Arabic
            "hi", // Hindi
            "nl", // Dutch
            "sv", // Swedish
            "no", // Norwegian
            "da", // Danish
            "fi", // Finnish
            "pl", // Polish
            "cs", // Czech
            "hu", // Hungarian
            "tr", // Turkish
            "he", // Hebrew
            "th", // Thai
            "vi", // Vietnamese
            "uk", // Ukrainian
            "bg", // Bulgarian
            "hr", // Croatian
            "sk", // Slovak
            "sl", // Slovenian
            "et", // Estonian
            "lv", // Latvian
            "lt", // Lithuanian
            "ro", // Romanian
            "el", // Greek
            "is", // Icelandic
            "mt", // Maltese
            "ga", // Irish
            "cy", // Welsh
            "eu", // Basque
            "ca", // Catalan
            "gl", // Galician
            "mn", // Mongolian
            "ml", // Malayalam
            "ta", // Tamil
            "te", // Telugu
            "kn", // Kannada
            "gu", // Gujarati
            "pa", // Punjabi
            "ur", // Urdu
            "fa", // Persian
            "sw", // Swahili
            "ms", // Malay
            "id", // Indonesian
            "tl"  // Filipino
        ]
    }
    
    /// Get human-readable language name from code
    func getLanguageName(for languageCode: String) -> String {
        let locale = Locale(identifier: "en")
        return locale.localizedString(forLanguageCode: languageCode) ?? languageCode.uppercased()
    }
    
    // MARK: - Text Analysis
    
    /// Analyze text to determine if it needs translation
    func needsTranslation(text: String, userPreferredLanguage: String) -> Bool {
        let detectedLanguage = detectLanguage(from: text)
        
        // If we can't detect or it matches user preference, no translation needed
        if detectedLanguage == userPreferredLanguage {
            return false
        }
        
        // Check confidence - only translate if we're confident about the detection
        let confidence = getLanguageConfidence(from: text)
        let detectedConfidence = confidence[detectedLanguage] ?? 0.0
        
        // Only suggest translation if confidence is above threshold
        return detectedConfidence > 0.7
    }
    
    /// Extract language metadata from text
    func analyzeTextLanguage(text: String) -> LanguageAnalysis {
        let detectedLanguage = detectLanguage(from: text)
        let confidence = getLanguageConfidence(from: text)
        let isSupported = isSupportedLanguage(detectedLanguage)
        let languageName = getLanguageName(for: detectedLanguage)
        
        return LanguageAnalysis(
            detectedLanguage: detectedLanguage,
            confidence: confidence[detectedLanguage] ?? 0.0,
            isSupported: isSupported,
            languageName: languageName,
            allHypotheses: confidence
        )
    }
}

// MARK: - Supporting Models

/// Result of language analysis
struct LanguageAnalysis {
    let detectedLanguage: String
    let confidence: Double
    let isSupported: Bool
    let languageName: String
    let allHypotheses: [String: Double]
    
    /// Whether the detection is confident enough to act on
    var isConfidentDetection: Bool {
        return confidence > 0.7
    }
    
    /// Whether this language is different from English
    var isNonEnglish: Bool {
        return detectedLanguage != "en"
    }
}
