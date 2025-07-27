//
//  UserApiKey.swift
//  ParentGuidance
//
//  Created by alex kerss on 27/07/2025.
//

import Foundation

/// Model representing a user's API key for a specific AI provider
struct UserApiKey: Codable, Identifiable {
    let id: String
    let userId: String
    let provider: ApiKeyProvider
    let apiKey: String
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case provider
        case apiKey = "api_key"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Custom initializer to handle provider enum conversion
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        apiKey = try container.decode(String.self, forKey: .apiKey)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        
        // Handle provider string to enum conversion
        let providerString = try container.decode(String.self, forKey: .provider)
        guard let providerEnum = ApiKeyProvider(rawValue: providerString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .provider,
                in: container,
                debugDescription: "Invalid provider value: \(providerString)"
            )
        }
        provider = providerEnum
        
        // Handle boolean fields that might come as strings or booleans
        if let isActiveBool = try? container.decode(Bool.self, forKey: .isActive) {
            isActive = isActiveBool
        } else if let isActiveString = try? container.decode(String.self, forKey: .isActive) {
            isActive = isActiveString.lowercased() == "true"
        } else {
            isActive = false
        }
    }
    
    // Custom encoder to ensure proper format
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(provider.rawValue, forKey: .provider)
        try container.encode(apiKey, forKey: .apiKey)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    /// Convenience initializer for creating new API keys
    init(
        userId: String,
        provider: ApiKeyProvider,
        apiKey: String,
        isActive: Bool = false
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.provider = provider
        self.apiKey = apiKey
        self.isActive = isActive
        
        let now = ISO8601DateFormatter().string(from: Date())
        self.createdAt = now
        self.updatedAt = now
    }
    
    /// Private initializer for helper methods
    private init(
        id: String,
        userId: String,
        provider: ApiKeyProvider,
        apiKey: String,
        isActive: Bool,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.userId = userId
        self.provider = provider
        self.apiKey = apiKey
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Returns a masked version of the API key for display purposes
    var maskedApiKey: String {
        guard apiKey.count > 10 else {
            return String(repeating: "*", count: apiKey.count)
        }
        
        let prefix = String(apiKey.prefix(4))
        let suffix = String(apiKey.suffix(4))
        let middle = String(repeating: "*", count: max(0, apiKey.count - 8))
        
        return "\(prefix)\(middle)\(suffix)"
    }
    
    /// Validates the API key format for the provider
    var isValidFormat: Bool {
        return provider.isValidApiKeyFormat(apiKey)
    }
    
    /// Returns the display name for the provider
    var providerDisplayName: String {
        return provider.displayName
    }
}

// MARK: - Hashable & Equatable

extension UserApiKey: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UserApiKey, rhs: UserApiKey) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Helper Extensions

extension UserApiKey {
    /// Creates a copy with updated active status
    func withActiveStatus(_ isActive: Bool) -> UserApiKey {
        return UserApiKey(
            id: self.id,
            userId: self.userId,
            provider: self.provider,
            apiKey: self.apiKey,
            isActive: isActive,
            createdAt: self.createdAt,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    /// Creates a copy with updated API key
    func withUpdatedApiKey(_ newApiKey: String) -> UserApiKey {
        return UserApiKey(
            id: self.id,
            userId: self.userId,
            provider: self.provider,
            apiKey: newApiKey,
            isActive: self.isActive,
            createdAt: self.createdAt,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }
}

/// Data structure for inserting new API keys into the database
struct UserApiKeyInsert: Codable {
    let user_id: String
    let provider: String
    let api_key: String
    let is_active: Bool
    let created_at: String
    let updated_at: String
}

/// Data structure for updating API keys in the database
struct UserApiKeyUpdate: Codable {
    let api_key: String?
    let is_active: Bool?
    let updated_at: String
    
    init(apiKey: String? = nil, isActive: Bool? = nil) {
        self.api_key = apiKey
        self.is_active = isActive
        self.updated_at = ISO8601DateFormatter().string(from: Date())
    }
}