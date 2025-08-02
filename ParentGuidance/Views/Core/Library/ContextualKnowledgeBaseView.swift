//
//  ContextualKnowledgeBaseView.swift
//  ParentGuidance
//
//  Created by alex kerss on 17/07/2025.
//

import SwiftUI

struct ContextualKnowledgeBaseView: View {
    let familyId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var insightCounts: [ContextCategory: Int] = [:]
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
                    
                    Text(String(localized: "library.insights.title"))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                // Deleted items link
                HStack {
                    Spacer()
                    
                    NavigationLink(destination: DeletedContextualInsightsView(
                        familyId: familyId,
                        category: nil
                    )) {
                        HStack(spacing: 6) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 14, weight: .medium))
                            Text(String(localized: "regulation.archive.button.viewDeleted"))
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(SemanticColors.accentBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel(String(localized: "regulation.archive.button.viewDeleted"))
                    .accessibilityHint("Double tap to view deleted insights")
                    .padding(.trailing, 8)
                }
                .padding(.bottom, 16)
                
                // Content
                if isLoading {
                    loadingView
                } else if hasError {
                    errorView
                } else {
                    categoryGridView
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
            
            Text(String(localized: "library.insights.loading"))
                .font(.system(size: 16))
                .foregroundColor(SemanticColors.tertiaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Text(String(localized: "library.insights.error.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            Text(String(localized: "library.insights.error.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.tertiaryText)
            
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
    
    private var categoryGridView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(ContextCategory.allCases, id: \.self) { category in
                    NavigationLink(destination: ContextCategoryView(
                        familyId: familyId,
                        category: category,
                        insightCount: insightCounts[category] ?? 0
                    )) {
                        CategoryCardContent(
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
            insightCounts = try await ContextualInsightService.shared.getInsightCounts(familyId: familyId)
            print("✅ Loaded insight counts: \(insightCounts)")
        } catch {
            print("❌ Failed to load insight counts: \(error)")
            hasError = true
        }
        
        isLoading = false
    }
}

struct CategoryCard: View {
    let category: ContextCategory
    let insightCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            CategoryCardContent(category: category, insightCount: insightCount)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryCardContent: View {
    let category: ContextCategory
    let insightCount: Int
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Icon
            Image(systemName: category.iconName)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(SemanticColors.accentBlue)
                .frame(width: 32, height: 32)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                if insightCount > 0 {
                    Text(String.localizedStringWithFormat(String(localized: "library.insights.category.count %lld"), insightCount))
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.tertiaryText)
                } else {
                    Text(String(localized: "library.insights.category.empty"))
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
        .if(colorScheme == .light) { view in
            view.cardShadow()
        }
    }
}


#Preview {
    ContextualKnowledgeBaseView(familyId: "preview-family-id")
}
