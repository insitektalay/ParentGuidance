//
//  TranslationStrategySelectionView.swift
//  ParentGuidance
//
//  Created by alex kerss on 19/07/2025.
//

import SwiftUI

struct TranslationStrategySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                            .foregroundColor(ColorPalette.white)
                        
                        Text(String(localized: "settings.familyLanguage.strategy.selection.description"))
                            .font(.system(size: 14))
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                        
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
            .background(ColorPalette.navy)
            .navigationTitle(String(localized: "settings.familyLanguage.strategy.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                    .foregroundColor(ColorPalette.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.save")) {
                        if selectedStrategy != currentStrategy {
                            showingConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(selectedStrategy != currentStrategy ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.5))
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
                    .foregroundColor(ColorPalette.brightBlue)
                
                Text(String(localized: "settings.familyLanguage.strategy.currentUsage.title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ColorPalette.white)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(localized: "settings.familyLanguage.strategy.currentUsage.familyType"))
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(metrics.isHighUsageFamily ? "High Usage" : "Low Usage")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(metrics.isHighUsageFamily ? .green : ColorPalette.white.opacity(0.8))
                }
                
                HStack {
                    Text(String(localized: "settings.familyLanguage.strategy.currentUsage.avgAccess"))
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(String(format: "%.1f per item", metrics.averageAccessesPerContent))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                }
                
                if metrics.isDualLanguageActive {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        
                        Text(String(localized: "settings.familyLanguage.strategy.currentUsage.dualLanguageActive"))
                            .font(.system(size: 14))
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.21, green: 0.22, blue: 0.33))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var costImplicationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 18))
                    .foregroundColor(ColorPalette.terracotta)
                
                Text(String(localized: "settings.familyLanguage.strategy.costImplications.title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ColorPalette.white)
                
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
                    color: ColorPalette.brightBlue
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
        .background(Color(red: 0.21, green: 0.22, blue: 0.33))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func costImplicationRow(strategy: TranslationGenerationStrategy, cost: String, benefit: String, color: Color) -> some View {
        HStack {
            Text(strategy.description.components(separatedBy: " (").first ?? strategy.description)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorPalette.white)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(cost)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                
                Text(benefit)
                    .font(.system(size: 11))
                    .foregroundColor(ColorPalette.white.opacity(0.7))
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
                                .foregroundColor(ColorPalette.white)
                            
                            if isRecommended {
                                Text(String(localized: "settings.familyLanguage.strategy.recommended"))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(ColorPalette.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ColorPalette.brightBlue)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(getStrategyDetail(strategy))
                            .font(.system(size: 14))
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.4))
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
            }
            .padding(16)
            .background(
                Color(red: 0.21, green: 0.22, blue: 0.33)
                    .opacity(isSelected ? 1.0 : 0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? ColorPalette.brightBlue.opacity(0.4) : 
                        isRecommended ? ColorPalette.brightBlue.opacity(0.2) :
                        ColorPalette.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
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
