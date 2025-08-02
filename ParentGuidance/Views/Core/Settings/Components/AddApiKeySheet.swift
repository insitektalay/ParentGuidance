//
//  AddApiKeySheet.swift
//  ParentGuidance
//
//  Created by alex kerss on 27/07/2025.
//

import SwiftUI

struct AddApiKeySheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiKeyService = MultiProviderApiKeyService.shared
    
    let provider: ApiKeyProvider
    let userProfile: UserProfile
    let onKeySaved: () -> Void
    
    @State private var apiKey: String = ""
    @State private var isValidating: Bool = false
    @State private var isSaving: Bool = false
    @State private var validationResult: ValidationResult?
    @State private var showingError: Bool = false
    @State private var errorMessage: String?
    @State private var makeActive: Bool = true
    
    enum ValidationResult {
        case success
        case failure(String)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    instructionsSection
                    apiKeyInputSection
                    
                    Spacer(minLength: 100)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SemanticColors.primaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(SemanticColors.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task {
                            await saveApiKey()
                        }
                    }
                    .foregroundColor(canSave ? provider.brandColor : SemanticColors.tertiaryText)
                    .disabled(!canSave || isSaving)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
            }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - Section Views
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: provider.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(provider.brandColor)
                    .frame(width: 40, height: 40)
                    .background(provider.brandColor.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add \(provider.displayName) API Key")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Text(provider.description)
                        .font(.body)
                        .foregroundColor(SemanticColors.secondaryText)
                }
                
                Spacer()
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 24)
    }
    
    private var instructionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Instructions")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                instructionStep1
                instructionStep2
                instructionStep3
            }
        }
        .padding(16)
        .background(SemanticColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }
    
    private var instructionStep1: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("1.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.secondaryText)
            
            Text("Visit \(provider.displayName)'s API key page")
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.primaryText)
            
            Spacer()
            
            Button("Open") {
                if let url = URL(string: provider.apiKeyURL) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(provider.brandColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(provider.brandColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
    
    private var instructionStep2: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("2.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.secondaryText)
            
            Text("Create a new API key")
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.primaryText)
        }
    }
    
    private var instructionStep3: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("3.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.secondaryText)
            
            Text("Copy and paste it below")
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.primaryText)
        }
    }
    
    private var apiKeyInputSection: some View {
        VStack(spacing: 16) {
            apiKeyInputField
            validationResultView
            actionButtonsView
            makeActiveToggleView
        }
        .padding(16)
        .background(SemanticColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }
    
    private var apiKeyInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(provider.displayName) API Key")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
                
                if isValidFormatting {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16))
                }
            }
            
            Text(provider.apiKeyFormatDescription)
                .font(.system(size: 12))
                .foregroundColor(SemanticColors.secondaryText)
            
            SecureField("Paste your API key here", text: $apiKey)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(SemanticColors.primaryBackground)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(SemanticColors.primaryText)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isValidFormatting ? .green : 
                            apiKey.isEmpty ? SemanticColors.accent.opacity(0.3) : 
                            .red,
                            lineWidth: 1
                        )
                )
            
            Text("Example: \(provider.exampleMaskedKey)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(SemanticColors.tertiaryText)
        }
    }
    
    @ViewBuilder
    private var validationResultView: some View {
        if let result = validationResult {
            HStack {
                switch result {
                case .success:
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("API key is valid and working")
                            .foregroundColor(.green)
                    }
                    .font(.system(size: 14))
                    
                case .failure(let error):
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Validation failed")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(.red.opacity(0.8))
                        }
                    }
                    .font(.system(size: 14))
                }
                
                Spacer()
            }
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            Button(isValidating ? "Validating..." : "Test API Key") {
                Task {
                    await validateApiKey()
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(SemanticColors.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isValidFormatting && !isValidating ? SemanticColors.accentBlue : SemanticColors.tertiaryText.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .disabled(!isValidFormatting || isValidating)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var makeActiveToggleView: some View {
        if hasExistingActiveKey {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set as active provider")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Text("This will replace your current active provider")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.secondaryText)
                }
                
                Spacer()
                
                Toggle("", isOn: $makeActive)
                    .tint(provider.brandColor)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValidFormatting: Bool {
        provider.isValidApiKeyFormat(apiKey)
    }
    
    private var canSave: Bool {
        guard isValidFormatting, let result = validationResult else { return false }
        if case .success = result {
            return true
        }
        return false
    }
    
    private var hasExistingActiveKey: Bool {
        apiKeyService.activeApiKey != nil
    }
    
    // MARK: - Methods
    
    private func validateApiKey() async {
        guard isValidFormatting else { return }
        
        await MainActor.run {
            isValidating = true
            validationResult = nil
        }
        
        do {
            let isValid = try await apiKeyService.validateApiKey(apiKey, provider: provider)
            
            await MainActor.run {
                isValidating = false
                validationResult = isValid ? .success : .failure("API key is not valid")
            }
            
        } catch {
            await MainActor.run {
                isValidating = false
                validationResult = .failure(error.localizedDescription)
            }
        }
    }
    
    private func saveApiKey() async {
        guard canSave else { return }
        
        await MainActor.run {
            isSaving = true
            errorMessage = nil
        }
        
        do {
            let _ = try await apiKeyService.addApiKey(
                userId: userProfile.id,
                provider: provider,
                apiKey: apiKey,
                makeActive: makeActive
            )
            
            await MainActor.run {
                isSaving = false
                onKeySaved()
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = "Failed to save API key: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddApiKeySheet(
        provider: .anthropic,
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
        onKeySaved: {}
    )
}