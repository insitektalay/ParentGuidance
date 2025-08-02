//
//  ApiKeyProviderCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 27/07/2025.
//

import SwiftUI

struct ApiKeyProviderCard: View {
    let provider: ApiKeyProvider
    let userApiKey: UserApiKey?
    let isActive: Bool
    let onAddKey: () -> Void
    let onSetActive: () -> Void
    let onDeleteKey: (UserApiKey) -> Void
    
    @State private var showingKeyDetails = false
    
    var body: some View {
        VStack(spacing: 12) {
            providerHeader
            keyDetailsSection
            actionButtonsSection
        }
        .padding(16)
        .background(SemanticColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isActive ? provider.brandColor.opacity(0.5) : SemanticColors.tertiaryText.opacity(0.3),
                    lineWidth: isActive ? 2 : 1
                )
        )
    }
    
    // MARK: - Component Views
    
    private var providerHeader: some View {
        HStack {
            providerInfo
            Spacer()
            if userApiKey != nil {
                statusIndicator
            }
        }
    }
    
    private var providerInfo: some View {
        HStack(spacing: 12) {
            Image(systemName: provider.iconName)
                .font(.system(size: 20))
                .foregroundColor(provider.brandColor)
                .frame(width: 32, height: 32)
                .background(provider.brandColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(provider.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Text(provider.description)
                    .font(.system(size: 12))
                    .foregroundColor(SemanticColors.secondaryText)
                    .lineLimit(2)
            }
        }
    }
    
    private var statusIndicator: some View {
        VStack(alignment: .trailing, spacing: 4) {
            statusBadge
            
            Button {
                showingKeyDetails.toggle()
            } label: {
                Image(systemName: showingKeyDetails ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(SemanticColors.tertiaryText)
            }
        }
    }
    
    private var statusBadge: some View {
        Group {
            if isActive {
                Text("Active")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.green.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Text("Configured")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(SemanticColors.secondaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(SemanticColors.tertiaryText.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
    
    @ViewBuilder
    private var keyDetailsSection: some View {
        if let apiKey = userApiKey, showingKeyDetails {
            VStack(spacing: 8) {
                Divider()
                    .background(SemanticColors.tertiaryText.opacity(0.5))
                
                HStack {
                    Text("API Key:")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.secondaryText)
                    
                    Spacer()
                    
                    Text(apiKey.maskedApiKey)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(SemanticColors.primaryText)
                }
                
                HStack {
                    Text("Added:")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.secondaryText)
                    
                    Spacer()
                    
                    Text(formatDate(apiKey.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.primaryText)
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            if let apiKey = userApiKey {
                configuredButtons(apiKey: apiKey)
            } else {
                unconfiguredButtons
            }
        }
    }
    
    private func configuredButtons(apiKey: UserApiKey) -> some View {
        HStack(spacing: 12) {
            if !isActive {
                Button("Set Active") {
                    onSetActive()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(provider.brandColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Spacer()
            
            Button {
                if let url = URL(string: provider.apiKeyURL) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                    Text("Get Key")
                }
            }
            .font(.system(size: 12))
            .foregroundColor(SemanticColors.secondaryText)
            
            Button("Delete") {
                onDeleteKey(apiKey)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.red)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    private var unconfiguredButtons: some View {
        HStack(spacing: 12) {
            Button("Add API Key") {
                onAddKey()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(SemanticColors.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(provider.brandColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Spacer()
            
            Button {
                if let url = URL(string: provider.apiKeyURL) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                    Text("Get \(provider.shortName) Key")
                }
            }
            .font(.system(size: 12))
            .foregroundColor(SemanticColors.secondaryText)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        
        return displayFormatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Active Provider
        ApiKeyProviderCard(
            provider: .openai,
            userApiKey: UserApiKey(
                userId: "test-user",
                provider: .openai,
                apiKey: "sk-proj-abcdefghijklmnopqrstuvwxyz1234567890",
                isActive: true
            ),
            isActive: true,
            onAddKey: {},
            onSetActive: {},
            onDeleteKey: { _ in }
        )
        
        // Configured but inactive
        ApiKeyProviderCard(
            provider: .anthropic,
            userApiKey: UserApiKey(
                userId: "test-user",
                provider: .anthropic,
                apiKey: "sk-ant-api03-abcdefghijklmnopqrstuvwxyz1234567890",
                isActive: false
            ),
            isActive: false,
            onAddKey: {},
            onSetActive: {},
            onDeleteKey: { _ in }
        )
        
        // Not configured
        ApiKeyProviderCard(
            provider: .xai,
            userApiKey: nil,
            isActive: false,
            onAddKey: {},
            onSetActive: {},
            onDeleteKey: { _ in }
        )
    }
    .padding()
    .background(SemanticColors.primaryBackground)
}