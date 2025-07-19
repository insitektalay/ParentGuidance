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
                            .foregroundColor(ColorPalette.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Text(String(localized: "library.insights.title"))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
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
                    categoryGridView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
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
                .foregroundColor(ColorPalette.white.opacity(0.8))
            
            Text(String(localized: "library.insights.loading"))
                .font(.system(size: 16))
                .foregroundColor(ColorPalette.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Text(String(localized: "library.insights.error.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(String(localized: "library.insights.error.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
            
            Button(String(localized: "common.retry")) {
                Task {
                    await loadInsightCounts()
                }
            }
            .foregroundColor(ColorPalette.terracotta)
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
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Icon
            Image(systemName: category.iconName)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(ColorPalette.brightBlue)
                .frame(width: 32, height: 32)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ColorPalette.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                if insightCount > 0 {
                    Text(String(localized: "library.insights.category.count \(insightCount)"))
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                } else {
                    Text(String(localized: "library.insights.category.empty"))
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Count badge
            if insightCount > 0 {
                Text("\(insightCount)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ColorPalette.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(ColorPalette.terracotta)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.21, green: 0.22, blue: 0.33))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


#Preview {
    ContextualKnowledgeBaseView(familyId: "preview-family-id")
}
