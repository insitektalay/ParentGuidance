//
//  AIProcessingSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 29/07/2025.
//

import SwiftUI

struct AIProcessingSection: View {
    @ObservedObject var viewState: SettingsViewState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title
            Text(String(localized: "settings.aiprocessing.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            // Section description
            Text(String(localized: "settings.aiprocessing.description"))
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                // Situation Analysis toggle
                aiProcessingToggle(
                    title: String(localized: "settings.aiprocessing.situationanalysis.title"),
                    description: String(localized: "settings.aiprocessing.situationanalysis.description"),
                    implications: String(localized: "settings.aiprocessing.situationanalysis.implications"),
                    isEnabled: viewState.enableSituationAnalysis,
                    onToggle: {
                        viewState.enableSituationAnalysis.toggle()
                        AIProcessingSettings.shared.setSituationAnalysisEnabled(viewState.enableSituationAnalysis)
                    }
                )
                
                Divider()
                    .background(ColorPalette.white.opacity(0.1))
                    .padding(.horizontal, 16)
                
                // Context Extraction toggle
                aiProcessingToggle(
                    title: String(localized: "settings.aiprocessing.contextextraction.title"),
                    description: String(localized: "settings.aiprocessing.contextextraction.description"),
                    implications: String(localized: "settings.aiprocessing.contextextraction.implications"),
                    isEnabled: viewState.enableContextExtraction,
                    onToggle: {
                        viewState.enableContextExtraction.toggle()
                        AIProcessingSettings.shared.setContextExtractionEnabled(viewState.enableContextExtraction)
                    }
                )
                
                Divider()
                    .background(ColorPalette.white.opacity(0.1))
                    .padding(.horizontal, 16)
                
                // Regulation Insights toggle
                aiProcessingToggle(
                    title: String(localized: "settings.aiprocessing.regulationinsights.title"),
                    description: String(localized: "settings.aiprocessing.regulationinsights.description"),
                    implications: String(localized: "settings.aiprocessing.regulationinsights.implications"),
                    isEnabled: viewState.enableRegulationInsights,
                    onToggle: {
                        viewState.enableRegulationInsights.toggle()
                        AIProcessingSettings.shared.setRegulationInsightsEnabled(viewState.enableRegulationInsights)
                    }
                )
                
                Divider()
                    .background(ColorPalette.white.opacity(0.1))
                    .padding(.horizontal, 16)
                
                // Coping Strategies toggle
                aiProcessingToggle(
                    title: String(localized: "settings.aiprocessing.copingstrategies.title"),
                    description: String(localized: "settings.aiprocessing.copingstrategies.description"),
                    implications: String(localized: "settings.aiprocessing.copingstrategies.implications"),
                    isEnabled: viewState.enableCopingStrategies,
                    onToggle: {
                        viewState.enableCopingStrategies.toggle()
                        AIProcessingSettings.shared.setCopingStrategiesEnabled(viewState.enableCopingStrategies)
                    }
                )
            }
            .background(ColorPalette.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Toggle Component
    
    private func aiProcessingToggle(
        title: String,
        description: String,
        implications: String,
        isEnabled: Bool,
        onToggle: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(ColorPalette.white.opacity(0.8))
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .tint(ColorPalette.brightBlue)
            }
            
            if !isEnabled {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.terracotta)
                    
                    Text(implications)
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.terracotta.opacity(0.9))
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
    }
}

