//
//  DeveloperSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct DeveloperSection: View {
    @Environment(\.colorScheme) private var colorScheme
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
}
