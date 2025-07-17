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
    @State private var selectedCategory: ContextCategory?
    
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
                    
                    Text("contextual knowledge base")
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
        .navigationDestination(item: $selectedCategory) { category in
            ContextCategoryView(
                familyId: familyId,
                category: category,
                insightCount: insightCounts[category] ?? 0
            )
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .foregroundColor(ColorPalette.white.opacity(0.8))
            
            Text("Loading insights...")
                .font(.system(size: 16))
                .foregroundColor(ColorPalette.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Text("Unable to load insights")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text("Please try again later")
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
            
            Button("Retry") {
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
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(ContextCategory.allCases, id: \.self) { category in
                    CategoryCard(
                        category: category,
                        insightCount: insightCounts[category] ?? 0,
                        onTap: {
                            selectedCategory = category
                        }
                    )
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
            VStack(alignment: .leading, spacing: 12) {
                // Icon and count
                HStack(alignment: .top) {
                    Image(systemName: category.iconName)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(ColorPalette.brightBlue)
                    
                    Spacer()
                    
                    if insightCount > 0 {
                        Text("\(insightCount)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ColorPalette.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ColorPalette.terracotta)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // Category name
                Text(category.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ColorPalette.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Spacer()
                
                // Insight count or empty state
                if insightCount > 0 {
                    Text("\(insightCount) insight\(insightCount == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                } else {
                    Text("No insights yet")
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.5))
                }
            }
            .padding(16)
            .frame(height: 140)
            .background(Color(red: 0.21, green: 0.22, blue: 0.33))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    ContextualKnowledgeBaseView(familyId: "preview-family-id")
}
