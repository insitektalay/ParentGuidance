//
//  ApiKeyProvider.swift
//  ParentGuidance
//
//  Created by alex kerss on 27/07/2025.
//

import Foundation
import SwiftUI

/// Enum representing supported AI providers for API keys
enum ApiKeyProvider: String, CaseIterable, Codable {
    case openai = "openai"
    case anthropic = "anthropic"
    case xai = "xai"
    case google = "google"
    
    /// Human-readable display name for the provider
    var displayName: String {
        switch self {
        case .openai:
            return "OpenAI"
        case .anthropic:
            return "Anthropic"
        case .xai:
            return "xAI"
        case .google:
            return "Google Generative AI"
        }
    }
    
    /// Short identifier used in UI
    var shortName: String {
        switch self {
        case .openai:
            return "OpenAI"
        case .anthropic:
            return "Claude"
        case .xai:
            return "Grok"
        case .google:
            return "Gemini"
        }
    }
    
    /// Description of the provider's capabilities
    var description: String {
        switch self {
        case .openai:
            return "GPT-4 and other OpenAI models for guidance generation"
        case .anthropic:
            return "Claude models for thoughtful parenting guidance"
        case .xai:
            return "Grok models for direct, helpful parenting advice"
        case .google:
            return "Gemini models for comprehensive parenting support"
        }
    }
    
    /// Website URL for the provider
    var websiteURL: String {
        switch self {
        case .openai:
            return "https://platform.openai.com"
        case .anthropic:
            return "https://console.anthropic.com"
        case .xai:
            return "https://console.x.ai"
        case .google:
            return "https://ai.google.dev"
        }
    }
    
    /// URL to get API keys
    var apiKeyURL: String {
        switch self {
        case .openai:
            return "https://platform.openai.com/api-keys"
        case .anthropic:
            return "https://console.anthropic.com/settings/keys"
        case .xai:
            return "https://console.x.ai/team"
        case .google:
            return "https://aistudio.google.com/app/apikey"
        }
    }
    
    /// Color associated with the provider for UI elements
    var brandColor: Color {
        switch self {
        case .openai:
            return Color(red: 0.16, green: 0.66, blue: 0.58) // OpenAI teal
        case .anthropic:
            return Color(red: 0.85, green: 0.55, blue: 0.40) // Anthropic orange
        case .xai:
            return Color(red: 0.0, green: 0.0, blue: 0.0) // xAI black
        case .google:
            return Color(red: 0.26, green: 0.52, blue: 0.96) // Google blue
        }
    }
    
    /// Icon name for the provider (SF Symbols)
    var iconName: String {
        switch self {
        case .openai:
            return "brain.head.profile"
        case .anthropic:
            return "message.and.waveform"
        case .xai:
            return "bolt.circle"
        case .google:
            return "sparkles"
        }
    }
    
    /// Validates API key format for the provider
    func isValidApiKeyFormat(_ apiKey: String) -> Bool {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch self {
        case .openai:
            // OpenAI keys start with "sk-" and are typically 51 characters
            return trimmedKey.hasPrefix("sk-") && trimmedKey.count >= 20
            
        case .anthropic:
            // Anthropic keys start with "sk-ant-" and are longer
            return trimmedKey.hasPrefix("sk-ant-") && trimmedKey.count >= 30
            
        case .xai:
            // xAI keys start with "xai-" (format may vary, being flexible)
            return trimmedKey.hasPrefix("xai-") && trimmedKey.count >= 20
            
        case .google:
            // Google AI Studio keys are typically 39 characters, alphanumeric
            return trimmedKey.count >= 20 && trimmedKey.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil
        }
    }
    
    /// Expected API key format description for user guidance
    var apiKeyFormatDescription: String {
        switch self {
        case .openai:
            return "Should start with 'sk-' followed by additional characters"
        case .anthropic:
            return "Should start with 'sk-ant-' followed by additional characters"
        case .xai:
            return "Should start with 'xai-' followed by additional characters"
        case .google:
            return "Should be a string of letters, numbers, and dashes"
        }
    }
    
    /// Example masked API key for UI
    var exampleMaskedKey: String {
        switch self {
        case .openai:
            return "sk-proj-****...****abcd"
        case .anthropic:
            return "sk-ant-****...****efgh"
        case .xai:
            return "xai-****...****ijkl"
        case .google:
            return "AIza****...****mnop"
        }
    }
    
    /// Models available for this provider (for future model selection)
    var availableModels: [String] {
        switch self {
        case .openai:
            return ["gpt-4", "gpt-4-turbo", "gpt-3.5-turbo"]
        case .anthropic:
            return ["claude-3-sonnet", "claude-3-haiku", "claude-3-opus"]
        case .xai:
            return ["grok-beta"]
        case .google:
            return ["gemini-pro", "gemini-pro-vision"]
        }
    }
    
    /// Default model for this provider
    var defaultModel: String {
        switch self {
        case .openai:
            return "gpt-4"
        case .anthropic:
            return "claude-3-sonnet"
        case .xai:
            return "grok-beta"
        case .google:
            return "gemini-pro"
        }
    }
    
    /// Whether this provider supports streaming responses
    var supportsStreaming: Bool {
        switch self {
        case .openai, .anthropic, .google:
            return true
        case .xai:
            return true // Assuming xAI supports streaming
        }
    }
    
    /// Whether this provider is currently supported in Edge Functions
    var isEdgeFunctionSupported: Bool {
        switch self {
        case .openai:
            return true // Already implemented
        case .anthropic, .xai, .google:
            return true // Will be implemented
        }
    }
}

// MARK: - Helper Extensions

extension ApiKeyProvider {
    /// Returns all providers that are currently supported
    static var supportedProviders: [ApiKeyProvider] {
        return allCases.filter { $0.isEdgeFunctionSupported }
    }
    
    /// Returns providers available for new users
    static var availableForNewUsers: [ApiKeyProvider] {
        return allCases // All providers available
    }
}

// MARK: - Sorting and Ordering

extension ApiKeyProvider: Comparable {
    static func < (lhs: ApiKeyProvider, rhs: ApiKeyProvider) -> Bool {
        // Define preferred order: OpenAI first, then alphabetical
        if lhs == .openai { return true }
        if rhs == .openai { return false }
        return lhs.displayName < rhs.displayName
    }
}

// MARK: - Identifiable for SwiftUI

extension ApiKeyProvider: Identifiable {
    var id: String { rawValue }
}