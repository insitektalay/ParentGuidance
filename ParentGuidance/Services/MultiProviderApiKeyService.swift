//
//  MultiProviderApiKeyService.swift
//  ParentGuidance
//
//  Created by alex kerss on 27/07/2025.
//

import Foundation
import SwiftUI
import Supabase

/// Service for managing multi-provider API keys
class MultiProviderApiKeyService: ObservableObject {
    static let shared = MultiProviderApiKeyService()
    
    // MARK: - Published Properties
    
    /// All API keys for the current user
    @Published var userApiKeys: [UserApiKey] = []
    
    /// Currently active API key
    @Published var activeApiKey: UserApiKey?
    
    /// Loading state for API operations
    @Published var isLoading: Bool = false
    
    /// Error message for UI display
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let supabase = SupabaseManager.shared.client
    private var currentUserId: String?
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Load all API keys for the specified user
    func loadApiKeys(for userId: String) async throws {
        print("🔑 [MultiProviderApiKeyService] Loading API keys for user: \(userId)")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        currentUserId = userId
        
        do {
            let response: [UserApiKey] = try await supabase
                .from("user_api_keys")
                .select("*")
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                userApiKeys = response
                activeApiKey = response.first { $0.isActive }
                isLoading = false
            }
            
            print("✅ [MultiProviderApiKeyService] Loaded \(response.count) API keys")
            if let activeKey = activeApiKey {
                print("   → Active provider: \(activeKey.provider.displayName)")
            } else {
                print("   → No active API key found")
            }
            
        } catch {
            print("❌ [MultiProviderApiKeyService] Failed to load API keys: \(error)")
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to load API keys: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Add a new API key for a provider
    func addApiKey(
        userId: String,
        provider: ApiKeyProvider,
        apiKey: String,
        makeActive: Bool = false
    ) async throws -> UserApiKey {
        print("🔑 [MultiProviderApiKeyService] Adding API key for provider: \(provider.displayName)")
        
        // Validate API key format
        guard provider.isValidApiKeyFormat(apiKey) else {
            let error = ApiKeyError.invalidFormat(provider: provider)
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
            throw error
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Create insert data
        let insertData = UserApiKeyInsert(
            user_id: userId,
            provider: provider.rawValue,
            api_key: apiKey,
            is_active: makeActive,
            created_at: ISO8601DateFormatter().string(from: Date()),
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        do {
            let response: [UserApiKey] = try await supabase
                .from("user_api_keys")
                .insert(insertData)
                .select("*")
                .execute()
                .value
            
            guard let newApiKey = response.first else {
                throw ApiKeyError.insertFailed
            }
            
            // Reload all keys to get the updated state
            try await loadApiKeys(for: userId)
            
            print("✅ [MultiProviderApiKeyService] API key added successfully")
            return newApiKey
            
        } catch {
            print("❌ [MultiProviderApiKeyService] Failed to add API key: \(error)")
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to add API key: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Update an existing API key
    func updateApiKey(
        keyId: String,
        newApiKey: String? = nil,
        makeActive: Bool? = nil
    ) async throws {
        print("🔑 [MultiProviderApiKeyService] Updating API key: \(keyId)")
        
        guard let userId = currentUserId else {
            throw ApiKeyError.noCurrentUser
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // If updating the API key value, validate format
        if let newKey = newApiKey,
           let existingKey = userApiKeys.first(where: { $0.id == keyId }) {
            guard existingKey.provider.isValidApiKeyFormat(newKey) else {
                let error = ApiKeyError.invalidFormat(provider: existingKey.provider)
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
                throw error
            }
        }
        
        let updateData = UserApiKeyUpdate(
            apiKey: newApiKey,
            isActive: makeActive
        )
        
        do {
            let response = try await supabase
                .from("user_api_keys")
                .update(updateData)
                .eq("id", value: keyId)
                .eq("user_id", value: userId) // Ensure user owns the key
                .execute()
            
            // Reload all keys to get the updated state
            try await loadApiKeys(for: userId)
            
            print("✅ [MultiProviderApiKeyService] API key updated successfully")
            
        } catch {
            print("❌ [MultiProviderApiKeyService] Failed to update API key: \(error)")
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to update API key: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Delete an API key
    func deleteApiKey(keyId: String) async throws {
        print("🔑 [MultiProviderApiKeyService] Deleting API key: \(keyId)")
        
        guard let userId = currentUserId else {
            throw ApiKeyError.noCurrentUser
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let response = try await supabase
                .from("user_api_keys")
                .delete()
                .eq("id", value: keyId)
                .eq("user_id", value: userId) // Ensure user owns the key
                .execute()
            
            // Reload all keys to get the updated state
            try await loadApiKeys(for: userId)
            
            print("✅ [MultiProviderApiKeyService] API key deleted successfully")
            
        } catch {
            print("❌ [MultiProviderApiKeyService] Failed to delete API key: \(error)")
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to delete API key: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Set a specific API key as active (deactivates all others)
    func setActiveApiKey(keyId: String) async throws {
        print("🔑 [MultiProviderApiKeyService] Setting active API key: \(keyId)")
        
        guard let userId = currentUserId else {
            throw ApiKeyError.noCurrentUser
        }
        
        // Find the key to activate
        guard let keyToActivate = userApiKeys.first(where: { $0.id == keyId }) else {
            throw ApiKeyError.keyNotFound
        }
        
        try await updateApiKey(keyId: keyId, makeActive: true)
        
        print("✅ [MultiProviderApiKeyService] Active API key set to: \(keyToActivate.provider.displayName)")
    }
    
    /// Get the active API key for a user
    func getActiveApiKey(for userId: String) async throws -> UserApiKey? {
        // If we don't have keys loaded or user changed, load them
        if currentUserId != userId || userApiKeys.isEmpty {
            try await loadApiKeys(for: userId)
        }
        
        return activeApiKey
    }
    
    /// Get API key for a specific provider
    func getApiKey(for provider: ApiKeyProvider, userId: String) async throws -> UserApiKey? {
        // If we don't have keys loaded or user changed, load them
        if currentUserId != userId || userApiKeys.isEmpty {
            try await loadApiKeys(for: userId)
        }
        
        return userApiKeys.first { $0.provider == provider }
    }
    
    /// Check if user has any API keys configured
    func hasAnyApiKeys(for userId: String) async throws -> Bool {
        if currentUserId != userId || userApiKeys.isEmpty {
            try await loadApiKeys(for: userId)
        }
        
        return !userApiKeys.isEmpty
    }
    
    /// Get all providers that have API keys configured
    func getConfiguredProviders(for userId: String) async throws -> [ApiKeyProvider] {
        if currentUserId != userId || userApiKeys.isEmpty {
            try await loadApiKeys(for: userId)
        }
        
        return userApiKeys.map { $0.provider }.sorted()
    }
    
    /// Validate an API key by testing it with the provider
    func validateApiKey(_ apiKey: String, provider: ApiKeyProvider) async throws -> Bool {
        print("🔑 [MultiProviderApiKeyService] Validating API key for: \(provider.displayName)")
        
        // First check format
        guard provider.isValidApiKeyFormat(apiKey) else {
            throw ApiKeyError.invalidFormat(provider: provider)
        }
        
        // Test the API key with a simple request via Edge Function
        do {
            let result = try await EdgeFunctionService.shared.callEdgeFunction(
                operation: "validate_key",
                variables: ["provider": provider.rawValue],
                apiKey: apiKey
            )
            
            if let success = result["success"] as? Bool {
                return success
            }
            
            return false
            
        } catch {
            print("❌ [MultiProviderApiKeyService] API key validation failed: \(error)")
            throw ApiKeyError.validationFailed(provider: provider, error: error)
        }
    }
    
    // MARK: - Utility Methods
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Reset service state
    func reset() {
        userApiKeys = []
        activeApiKey = nil
        currentUserId = nil
        isLoading = false
        errorMessage = nil
    }
    
    /// Get display summary of current state
    var stateSummary: String {
        if let activeKey = activeApiKey {
            return "Active: \(activeKey.provider.displayName) (\(userApiKeys.count) total keys)"
        } else if !userApiKeys.isEmpty {
            return "\(userApiKeys.count) keys configured, none active"
        } else {
            return "No API keys configured"
        }
    }
}

// MARK: - Error Types

enum ApiKeyError: LocalizedError {
    case invalidFormat(provider: ApiKeyProvider)
    case insertFailed
    case updateFailed
    case deleteFailed
    case keyNotFound
    case noCurrentUser
    case validationFailed(provider: ApiKeyProvider, error: Error)
    case duplicateProvider(provider: ApiKeyProvider)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat(let provider):
            return "Invalid API key format for \(provider.displayName). \(provider.apiKeyFormatDescription)"
        case .insertFailed:
            return "Failed to save the API key to the database"
        case .updateFailed:
            return "Failed to update the API key"
        case .deleteFailed:
            return "Failed to delete the API key"
        case .keyNotFound:
            return "The specified API key was not found"
        case .noCurrentUser:
            return "No current user session available"
        case .validationFailed(let provider, let error):
            return "API key validation failed for \(provider.displayName): \(error.localizedDescription)"
        case .duplicateProvider(let provider):
            return "An API key for \(provider.displayName) already exists"
        }
    }
}

// MARK: - Legacy Compatibility

extension MultiProviderApiKeyService {
    /// Get API key in legacy format (for backward compatibility during migration)
    func getLegacyApiKey(for userId: String) async throws -> String? {
        if let activeKey = try await getActiveApiKey(for: userId) {
            return activeKey.apiKey
        }
        return nil
    }
    
    /// Get active provider name in legacy format
    func getLegacyProviderName(for userId: String) async throws -> String? {
        if let activeKey = try await getActiveApiKey(for: userId) {
            return activeKey.provider.rawValue
        }
        return nil
    }
}