//
//  DeveloperSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct DeveloperSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var appCoordinator: AppCoordinator
    @ObservedObject var viewState: SettingsViewState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "developer.settings.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(SemanticColors.primaryText)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "developer.settings.edgeFunctionTesting"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SemanticColors.primaryText)
                
                // Feature flag toggles
                featureFlagToggles
                
                // Status indicators
                featureFlagStatus
                
                // Developer Tools Section
                developerToolsSection
                
                // Time Machine Admin Access
                #if DEBUG
                timeMachineAdminSection
                #endif
            }
            .padding(16)
            .background(SemanticColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: colorScheme == .light ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Feature Flag Components
    
    private var featureFlagToggles: some View {
        VStack(spacing: 12) {
            featureFlagToggle("Translation", isEnabled: viewState.translationUseEdgeFunction) {
                viewState.translationUseEdgeFunction.toggle()
                TranslationService.setUseEdgeFunction(viewState.translationUseEdgeFunction)
            }
            
            featureFlagToggle("Conversation", isEnabled: viewState.conversationUseEdgeFunction) {
                viewState.conversationUseEdgeFunction.toggle()
                ConversationService.setUseEdgeFunction(viewState.conversationUseEdgeFunction)
            }
            
            featureFlagToggle("Framework", isEnabled: viewState.frameworkUseEdgeFunction) {
                viewState.frameworkUseEdgeFunction.toggle()
                FrameworkGenerationService.setUseEdgeFunction(viewState.frameworkUseEdgeFunction)
            }
            
            featureFlagToggle("Context", isEnabled: viewState.contextUseEdgeFunction) {
                viewState.contextUseEdgeFunction.toggle()
                ContextualInsightService.setUseEdgeFunction(viewState.contextUseEdgeFunction)
            }
            
            featureFlagToggle("Guidance", isEnabled: viewState.guidanceUseEdgeFunction) {
                viewState.guidanceUseEdgeFunction.toggle()
                GuidanceGenerationService.setUseEdgeFunction(viewState.guidanceUseEdgeFunction)
            }
        }
    }
    
    private func featureFlagToggle(_ name: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.primaryText)
            
            Spacer()
            
            Button(action: {
                // Add haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Execute the action
                action()
            }) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isEnabled ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    Text(isEnabled ? String(localized: "developer.settings.edgeFunction") : String(localized: "developer.settings.directApi"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(SemanticColors.cardBackground.opacity(isEnabled ? 1.0 : 0.6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isEnabled ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var featureFlagStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "common.label.status"))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            Text(String(localized: "developer.testing.instructions"))
                .font(.system(size: 12))
                .foregroundColor(SemanticColors.secondaryText)
                .lineLimit(nil)
        }
    }
    
    private var timeMachineAdminSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.vertical, 8)
            
            Text("Time Machine Admin")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            NavigationLink(destination: RegenAdminView().environmentObject(appCoordinator)) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Regeneration Admin")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SemanticColors.primaryText)
                        
                        Text("Time machine data regeneration tools")
                            .font(.system(size: 11))
                            .foregroundColor(SemanticColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.tertiaryText)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var developerToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.vertical, 8)
            
            Text("Developer Tools")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            VStack(spacing: 12) {
                // Experiment Builder
                NavigationLink(destination: ExperimentBuilderView().environmentObject(appCoordinator)) {
                    developerToolRow(
                        icon: "hammer",
                        title: "Experiment Builder",
                        description: "Configure and run AI experiments"
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Experiment Leaderboard
                NavigationLink(destination: LeaderboardView().environmentObject(appCoordinator)) {
                    developerToolRow(
                        icon: "list.star",
                        title: "Experiment Leaderboard",
                        description: "View experiment results and rankings"
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Data Hygiene
                NavigationLink(destination: DataHygieneView().environmentObject(appCoordinator)) {
                    developerToolRow(
                        icon: "wand.and.stars",
                        title: "Data Hygiene",
                        description: "Clean up and maintain data quality"
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Run Logs
                NavigationLink(destination: RunLogView(regenRunId: UUID()).environmentObject(appCoordinator)) {
                    developerToolRow(
                        icon: "doc.text.magnifyingglass",
                        title: "Run Logs",
                        description: "View detailed experiment execution logs"
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func developerToolRow(icon: String, title: String, description: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SemanticColors.primaryText)
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(SemanticColors.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(SemanticColors.tertiaryText)
        }
        .padding(.vertical, 4)
    }
}
