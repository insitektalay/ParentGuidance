//
//  ApiKeyManagementView.swift
//  ParentGuidance
//
//  Created by alex kerss on 27/07/2025.
//

import SwiftUI

struct ApiKeyManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiKeyService = MultiProviderApiKeyService.shared
    @State private var showingAddKeySheet = false
    @State private var selectedProvider: ApiKeyProvider?
    @State private var showingDeleteConfirmation = false
    @State private var keyToDelete: UserApiKey?
    
    let userProfile: UserProfile
    let onApiKeySaved: (() -> Void)?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section
                    VStack(spacing: 8) {
                        Text("API Key Management")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorPalette.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Manage your AI provider API keys and switch between different services")
                            .font(.body)
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 24)
                    
                    // Provider Cards
                    VStack(spacing: 16) {
                        HStack {
                            Text("Available Providers")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(ColorPalette.white)
                            
                            Spacer()
                            
                            if apiKeyService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(ColorPalette.white)
                            }
                        }
                        
                        ForEach(ApiKeyProvider.allCases.sorted()) { provider in
                            ApiKeyProviderCard(
                                provider: provider,
                                userApiKey: getUserApiKey(for: provider),
                                isActive: isActiveProvider(provider),
                                onAddKey: {
                                    selectedProvider = provider
                                    showingAddKeySheet = true
                                },
                                onSetActive: {
                                    Task {
                                        await setActiveProvider(provider)
                                    }
                                },
                                onDeleteKey: { apiKey in
                                    keyToDelete = apiKey
                                    showingDeleteConfirmation = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Current Active Provider Summary
                    if let activeKey = apiKeyService.activeApiKey {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Active Provider")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(ColorPalette.white)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: activeKey.provider.iconName)
                                    .foregroundColor(activeKey.provider.brandColor)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(activeKey.provider.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ColorPalette.white)
                                    
                                    Text("All AI operations will use this provider")
                                        .font(.system(size: 12))
                                        .foregroundColor(ColorPalette.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Text("Active")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.green.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .padding(16)
                        .background(ColorPalette.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ColorPalette.white.opacity(0.8))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onApiKeySaved?()
                        dismiss()
                    }
                    .foregroundColor(ColorPalette.terracotta)
                }
            }
        }
        .onAppear {
            loadApiKeys()
        }
        .sheet(isPresented: $showingAddKeySheet) {
            if let provider = selectedProvider {
                AddApiKeySheet(
                    provider: provider,
                    userProfile: userProfile,
                    onKeySaved: {
                        loadApiKeys()
                        onApiKeySaved?()
                    }
                )
            }
        }
        .alert("Delete API Key", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let key = keyToDelete {
                    Task {
                        await deleteApiKey(key)
                    }
                }
            }
        } message: {
            if let key = keyToDelete {
                Text("Are you sure you want to delete your \(key.provider.displayName) API key? This action cannot be undone.")
            }
        }
        .alert("Error", isPresented: .init(
            get: { apiKeyService.errorMessage != nil },
            set: { _ in apiKeyService.clearError() }
        )) {
            Button("OK") {
                apiKeyService.clearError()
            }
        } message: {
            Text(apiKeyService.errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadApiKeys() {
        Task {
            do {
                try await apiKeyService.loadApiKeys(for: userProfile.id)
            } catch {
                print("Failed to load API keys: \(error)")
            }
        }
    }
    
    private func getUserApiKey(for provider: ApiKeyProvider) -> UserApiKey? {
        return apiKeyService.userApiKeys.first { $0.provider == provider }
    }
    
    private func isActiveProvider(_ provider: ApiKeyProvider) -> Bool {
        return apiKeyService.activeApiKey?.provider == provider
    }
    
    private func setActiveProvider(_ provider: ApiKeyProvider) async {
        guard let apiKey = getUserApiKey(for: provider) else { return }
        
        do {
            try await apiKeyService.setActiveApiKey(keyId: apiKey.id)
        } catch {
            print("Failed to set active provider: \(error)")
        }
    }
    
    private func deleteApiKey(_ apiKey: UserApiKey) async {
        do {
            try await apiKeyService.deleteApiKey(keyId: apiKey.id)
            keyToDelete = nil
        } catch {
            print("Failed to delete API key: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    ApiKeyManagementView(
        userProfile: UserProfile(
            userId: "test-id",
            email: "test@example.com",
            selectedPlan: "api",
            planSetupComplete: true,
            childDetailsComplete: true,
            preferredLanguage: "en",
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z"
        ),
        onApiKeySaved: {}
    )
}

// MARK: - Convenience Initializer for UserProfile

extension UserProfile {
    init(
        userId: String,
        email: String?,
        selectedPlan: String?,
        planSetupComplete: Bool,
        childDetailsComplete: Bool,
        preferredLanguage: String = "en",
        createdAt: String,
        updatedAt: String
    ) {
        self.id = userId
        self.familyId = nil
        self.email = email
        self.fullName = nil
        self.role = nil
        self.selectedPlan = selectedPlan
        self.planSetupComplete = planSetupComplete
        self.childDetailsComplete = childDetailsComplete
        self.onboardingCompletedAt = nil
        self.subscriptionStatus = nil
        self.subscriptionId = nil
        self.preferredLanguage = preferredLanguage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}