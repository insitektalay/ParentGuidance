//
//  FoundationToolsSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct FoundationToolsSection: View {
    @ObservedObject var frameworkState: SettingsFrameworkState
    @EnvironmentObject var appCoordinator: AppCoordinator
    @ObservedObject var viewState: SettingsViewState
    
    let onLoadUserProfile: () async -> Void
    let onLoadFamilyLanguageData: () async -> Void
    let onLoadFeatureFlagStates: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "settings.foundationTools.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                if frameworkState.isLoading {
                    loadingFrameworkView
                } else if let errorMessage = frameworkState.errorMessage {
                    errorFrameworkView(errorMessage)
                } else if frameworkState.frameworks.isEmpty {
                    noFrameworksView
                } else {
                    frameworkListView
                }
            }
            .padding(16)
            .background(ColorPalette.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
        .onAppear {
            Task {
                await frameworkState.loadFrameworks(familyId: appCoordinator.currentUserId)
                await onLoadUserProfile()
                await onLoadFamilyLanguageData()
                await onLoadFeatureFlagStates()
            }
        }
    }
    
    // MARK: - Framework State Views
    
    private var loadingFrameworkView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(ColorPalette.white)
            
            Text(String(localized: "settings.foundationTools.loading"))
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
        }
    }
    
    private func errorFrameworkView(_ errorMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "settings.foundationTools.error"))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(errorMessage)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
            
            Button(String(localized: "common.tryAgain")) {
                Task {
                    await frameworkState.loadFrameworks(familyId: appCoordinator.currentUserId)
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(ColorPalette.terracotta)
        }
    }
    
    private var frameworkListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with count
            Text(String(localized: "settings.foundationTools.frameworks \(frameworkState.frameworks.count)"))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            // Framework cards
            ForEach(frameworkState.frameworks, id: \.id) { framework in
                FrameworkCard(
                    framework: framework,
                    isActive: frameworkState.activeFrameworkIds.contains(framework.id),
                    onToggle: {
                        Task {
                            await frameworkState.toggleFramework(frameworkId: framework.id)
                        }
                    },
                    onRemove: {
                        frameworkState.prepareForRemoval(framework: framework)
                    }
                )
            }
        }
    }
    
    private var noFrameworksView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "settings.foundationTools.status"))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(String(localized: "settings.foundationTools.noFrameworks"))
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
            
            Text(String(localized: "settings.foundationTools.generateHint"))
                .font(.system(size: 12))
                .foregroundColor(ColorPalette.white.opacity(0.6))
                .lineLimit(nil)
            
            Button(String(localized: "settings.foundationTools.goToLibrary")) {
                // TODO: Navigate to Library tab
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(ColorPalette.terracotta)
        }
    }
}
