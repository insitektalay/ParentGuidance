//
//  TranslationStrategySelectionView.swift
//  ParentGuidance
//
//  Created by alex kerss on 19/07/2025.
//

import SwiftUI

struct TranslationStrategySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let currentStrategy: TranslationGenerationStrategy
    let familyUsageMetrics: TranslationQueueManager.FamilyUsageMetrics?
    let onStrategySelected: (TranslationGenerationStrategy) -> Void
    
    @State private var selectedStrategy: TranslationGenerationStrategy
    @State private var showingConfirmation = false
    
    init(
        currentStrategy: TranslationGenerationStrategy,
        familyUsageMetrics: TranslationQueueManager.FamilyUsageMetrics?,
        onStrategySelected: @escaping (TranslationGenerationStrategy) -> Void
    ) {
        self.currentStrategy = currentStrategy
        self.familyUsageMetrics = familyUsageMetrics
        self.onStrategySelected = onStrategySelected
        self._selectedStrategy = State(initialValue: currentStrategy)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with current usage info
                    if let metrics = familyUsageMetrics {
                        currentUsageCard(metrics: metrics)
                    }
                    
                    // Strategy selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text(String(localized: "settings.familyLanguage.strategy.selection.title"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(SemanticColors.primaryText)
                        
                        Text(String(localized: "settings.familyLanguage.strategy.selection.description"))
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.secondaryText)
                        
                        VStack(spacing: 12) {
                            ForEach(TranslationGenerationStrategy.allCases, id: \.self) { strategy in
                                StrategyOptionCard(
                                    strategy: strategy,
                                    isSelected: selectedStrategy == strategy,
                                    isRecommended: strategy == getRecommendedStrategy(),
                                    onSelect: {
                                        selectedStrategy = strategy
                                    }
                                )
                            }
                        }
                    }
                    
                    // Cost implications
                    costImplicationsCard
                }
                .padding(24)
                .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SemanticColors.primaryBackground)
            .navigationTitle(String(localized: "settings.familyLanguage.strategy.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                    .foregroundColor(SemanticColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.save")) {
                        if selectedStrategy != currentStrategy {
                            showingConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(selectedStrategy != currentStrategy ? SemanticColors.accentBlue : SemanticColors.tertiaryText)
                    .disabled(selectedStrategy == currentStrategy)
                }
            }
        }
        .alert(String(localized: "settings.familyLanguage.strategy.confirmation.title"), isPresented: $showingConfirmation) {
            Button(String(localized: "common.cancel"), role: .cancel) {
                showingConfirmation = false
            }
            Button(String(localized: "common.confirm")) {
                onStrategySelected(selectedStrategy)
                dismiss()
            }
        } message: {
            Text(String(localized: "settings.familyLanguage.strategy.confirmation.message"))
        }
    }
    
    private func currentUsageCard(metrics: TranslationQueueManager.FamilyUsageMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                    .foregroundColor(SemanticColors.accentBlue)
                
                Text(String(localized: "settings.familyLanguage.strategy.currentUsage.title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(localized: "settings.familyLanguage.strategy.currentUsage.familyType"))
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                    
                    Spacer()
                    
                    Text(metrics.isHighUsageFamily ? String(localized: "family.usage.high") : String(localized: "family.usage.low"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(metrics.isHighUsageFamily ? .green : SemanticColors.secondaryText)
                }
                
                HStack {
                    Text(String(localized: "settings.familyLanguage.strategy.currentUsage.avgAccess"))
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f per item", metrics.averageAccessesPerContent))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                }
                
                if metrics.isDualLanguageActive {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        
                        Text(String(localized: "settings.familyLanguage.strategy.currentUsage.dualLanguageActive"))
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.secondaryText)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(SemanticColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: colorScheme == .light ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
    }
    
    private var costImplicationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 18))
                    .foregroundColor(SemanticColors.accent)
                
                Text(String(localized: "settings.familyLanguage.strategy.costImplications.title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                costImplicationRow(
                    strategy: .immediate,
                    cost: "Higher",
                    benefit: "Instant access",
                    color: .red
                )
                
                costImplicationRow(
                    strategy: .hybrid,
                    cost: "Balanced",
                    benefit: "Smart optimization",
                    color: SemanticColors.accentBlue
                )
                
                costImplicationRow(
                    strategy: .onDemand,
                    cost: "Lower",
                    benefit: "Cost-effective",
                    color: .green
                )
            }
        }
        .padding(16)
        .background(SemanticColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: colorScheme == .light ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
    }
    
    private func costImplicationRow(strategy: TranslationGenerationStrategy, cost: String, benefit: String, color: Color) -> some View {
        HStack {
            Text(strategy.description.components(separatedBy: " (").first ?? strategy.description)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(cost)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                
                Text(benefit)
                    .font(.system(size: 11))
                    .foregroundColor(SemanticColors.secondaryText)
            }
        }
    }
    
    private func getRecommendedStrategy() -> TranslationGenerationStrategy? {
        guard let metrics = familyUsageMetrics else { return nil }
        
        if metrics.isHighUsageFamily && metrics.isDualLanguageActive {
            return .immediate
        } else if metrics.averageAccessesPerContent < 2.0 {
            return .onDemand
        } else {
            return .hybrid
        }
    }
}

struct StrategyOptionCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let strategy: TranslationGenerationStrategy
    let isSelected: Bool
    let isRecommended: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(strategy.description.components(separatedBy: " (").first ?? strategy.description)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(SemanticColors.primaryText)
                            
                            if isRecommended {
                                Text(String(localized: "settings.familyLanguage.strategy.recommended"))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(SemanticColors.primaryText)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(SemanticColors.accentBlue)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(getStrategyDetail(strategy))
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.secondaryText)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? SemanticColors.accentBlue : SemanticColors.tertiaryText)
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
            }
            .padding(16)
            .background(
                SemanticColors.cardBackground
                    .opacity(isSelected ? 1.0 : 0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? SemanticColors.accentBlue.opacity(0.4) : 
                        isRecommended ? SemanticColors.accentBlue.opacity(0.2) :
                        SemanticColors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: colorScheme == .light ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
        }
    }
    
    private func getStrategyDetail(_ strategy: TranslationGenerationStrategy) -> String {
        switch strategy {
        case .immediate:
            return String(localized: "settings.familyLanguage.strategy.immediate.detail")
        case .onDemand:
            return String(localized: "settings.familyLanguage.strategy.onDemand.detail")
        case .hybrid:
            return String(localized: "settings.familyLanguage.strategy.hybrid.detail")
        }
    }
}

#Preview {
    TranslationStrategySelectionView(
        currentStrategy: .hybrid,
        familyUsageMetrics: TranslationQueueManager.FamilyUsageMetrics(
            familyId: "test",
            totalContentAccesses: 50,
            uniqueContentAccessed: 15,
            averageAccessesPerContent: 3.3,
            languageBreakdown: ["en": 30, "es": 20]
        ),
        onStrategySelected: { _ in }
    )
}
