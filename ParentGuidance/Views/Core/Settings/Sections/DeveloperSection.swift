//
//  DeveloperSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct DeveloperSection: View {
    @ObservedObject var viewState: SettingsViewState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "developer.settings.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "developer.settings.edgeFunctionTesting"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ColorPalette.white)
                
                // Feature flag toggles
                featureFlagToggles
                
                // Status indicators
                featureFlagStatus
            }
            .padding(16)
            .background(ColorPalette.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
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
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ColorPalette.white.opacity(isEnabled ? 0.15 : 0.1))
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
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(String(localized: "developer.testing.instructions"))
                .font(.system(size: 12))
                .foregroundColor(ColorPalette.white.opacity(0.7))
                .lineLimit(nil)
        }
    }
}
