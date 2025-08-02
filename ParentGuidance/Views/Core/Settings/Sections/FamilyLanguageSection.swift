//
//  FamilyLanguageSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct FamilyLanguageSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewState: SettingsViewState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "settings.familyLanguage.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(SemanticColors.primaryText)
                .padding(.horizontal, 16)
            
            VStack(spacing: 12) {
                // Family Language Overview
                familyLanguageOverviewCard
                
                // Translation Strategy Selection
                translationStrategyCard
                
                // Usage Analytics (if data available)
                if let metrics = viewState.familyUsageMetrics {
                    usageAnalyticsCard(metrics: metrics)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Family Language Components
    
    private var familyLanguageOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 18))
                    .foregroundColor(SemanticColors.accentBlue)
                
                Text(String(localized: "settings.familyLanguage.overview.title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
                
                if viewState.isLoadingFamilyLanguage {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(SemanticColors.primaryText)
                }
            }
            
            if let config = viewState.familyLanguageConfig {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(String(localized: "settings.familyLanguage.overview.members"))
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.secondaryText)
                        
                        Spacer()
                        
                        Text("\(config.memberLanguages.count) members")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SemanticColors.primaryText)
                    }
                    
                    HStack {
                        Text(String(localized: "settings.familyLanguage.overview.languages"))
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.secondaryText)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            ForEach(config.uniqueLanguages, id: \.self) { languageCode in
                                Text(languageCode.uppercased())
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(SemanticColors.primaryText)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(SemanticColors.accent.opacity(0.6))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    
                    HStack {
                        Text(String(localized: "settings.familyLanguage.overview.needsTranslation"))
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.secondaryText)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: config.needsDualLanguage ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(config.needsDualLanguage ? .green : SemanticColors.tertiaryText)
                            
                            Text(config.needsDualLanguage ? String(localized: "common.button.yes") : String(localized: "common.button.no"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SemanticColors.primaryText)
                        }
                    }
                }
            } else {
                Text(String(localized: "settings.familyLanguage.overview.notAvailable"))
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.tertiaryText)
            }
        }
        .padding(16)
        .background(SemanticColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: colorScheme == .light ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
    }
    
    private var translationStrategyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gear")
                    .font(.system(size: 18))
                    .foregroundColor(SemanticColors.accentBlue)
                
                Text(String(localized: "settings.familyLanguage.strategy.title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
                
                Button(String(localized: "settings.familyLanguage.strategy.change")) {
                    viewState.showingStrategySelection = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.accentBlue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(localized: "settings.familyLanguage.strategy.current"))
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                    
                    Spacer()
                    
                    Text(viewState.currentTranslationStrategy.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                        .lineLimit(1)
                }
                
                Text(getStrategyDescription(viewState.currentTranslationStrategy))
                    .font(.system(size: 12))
                    .foregroundColor(SemanticColors.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(SemanticColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: colorScheme == .light ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
    }
    
    private func usageAnalyticsCard(metrics: TranslationQueueManager.FamilyUsageMetrics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar")
                    .font(.system(size: 18))
                    .foregroundColor(SemanticColors.accentBlue)
                
                Text(String(localized: "settings.familyLanguage.analytics.title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(localized: "settings.familyLanguage.analytics.totalContent"))
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(metrics.uniqueContentAccessed)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                }
                
                HStack {
                    Text(String(localized: "settings.familyLanguage.analytics.averageAccess"))
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f per item", metrics.averageAccessesPerContent))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                }
                
                if !metrics.languageBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "settings.familyLanguage.analytics.languageUsage"))
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.secondaryText)
                        
                        HStack(spacing: 8) {
                            ForEach(Array(metrics.languageBreakdown.prefix(3)), id: \.key) { language, count in
                                HStack(spacing: 4) {
                                    Text(language.uppercased())
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(SemanticColors.primaryText)
                                    
                                    Text("\(count)")
                                        .font(.system(size: 11))
                                        .foregroundColor(SemanticColors.secondaryText)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(SemanticColors.accent.opacity(0.4))
                                .cornerRadius(4)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(SemanticColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: colorScheme == .light ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
    }
    
    private func getStrategyDescription(_ strategy: TranslationGenerationStrategy) -> String {
        switch strategy {
        case .immediate:
            return String(localized: "settings.familyLanguage.strategy.immediate.description")
        case .onDemand:
            return String(localized: "settings.familyLanguage.strategy.onDemand.description")
        case .hybrid:
            return String(localized: "settings.familyLanguage.strategy.hybrid.description")
        }
    }
}
