//
//  RegulationInsightsView.swift
//  ParentGuidance
//
//  Created by alex kerss on 18/07/2025.
//

import SwiftUI

struct RegulationInsightsView: View {
    let familyId: String
    @Environment(\.dismiss) private var dismiss
    @State private var insightCounts: [RegulationCategory: Int] = [:]
    @State private var isLoading = true
    @State private var hasError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .center, spacing: 12) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(SemanticColors.primaryText)
                    }
                    
                    Spacer()
                    
                    Text(String(localized: "regulation.insights.title"))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                // Content
                if isLoading {
                    loadingView
                } else if hasError {
                    errorView
                } else {
                    categoryListView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SemanticColors.primaryBackground)
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                await loadInsightCounts()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .foregroundColor(SemanticColors.secondaryText)
            
            Text(String(localized: "regulation.insights.loading"))
                .font(.system(size: 16))
                .foregroundColor(SemanticColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Text(String(localized: "regulation.insights.error.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            Text(String(localized: "regulation.insights.error.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.secondaryText)
            
            Button(String(localized: "common.retry")) {
                Task {
                    await loadInsightCounts()
                }
            }
            .foregroundColor(SemanticColors.accent)
            .font(.system(size: 16, weight: .medium))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var categoryListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(RegulationCategory.allCases, id: \.self) { category in
                    NavigationLink(destination: RegulationCategoryView(
                        familyId: familyId,
                        category: category,
                        insightCount: insightCounts[category] ?? 0
                    )) {
                        RegulationCategoryCardContent(
                            category: category,
                            insightCount: insightCounts[category] ?? 0
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100) // Space for tab bar
        }
    }
    
    @MainActor
    private func loadInsightCounts() async {
        isLoading = true
        hasError = false
        
        do {
            insightCounts = try await ContextualInsightService.shared.getRegulationInsightCounts(familyId: familyId)
            print("✅ Loaded regulation insight counts: \(insightCounts)")
        } catch {
            print("❌ Failed to load regulation insight counts: \(error)")
            hasError = true
        }
        
        isLoading = false
    }
}

struct RegulationCategoryCardContent: View {
    let category: RegulationCategory
    let insightCount: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Icon
            Image(systemName: category.iconName)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(SemanticColors.accentBlue)
                .frame(width: 32, height: 32)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(category.parentFriendlyName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                if insightCount > 0 {
                    Text(String(localized: "regulation.insights.count \(insightCount)"))
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                } else {
                    Text(String(localized: "regulation.insights.empty"))
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.tertiaryText)
                }
            }
            
            Spacer()
            
            // Count badge
            if insightCount > 0 {
                Text("\(insightCount)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(SemanticColors.primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(SemanticColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SemanticColors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SemanticColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - RegulationCategory Icon Extension

extension RegulationCategory {
    var iconName: String {
        switch self {
        case .core:
            return "heart.circle.fill"
        case .adhd:
            return "target"
        case .mildAutism:
            return "brain.head.profile"
        case .copingStrategies:
            return "shield.checkered"
        }
    }
}

#Preview {
    RegulationInsightsView(familyId: "preview-family-id")
}
