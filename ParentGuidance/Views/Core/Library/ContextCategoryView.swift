//
//  ContextCategoryView.swift
//  ParentGuidance
//
//  Created by alex kerss on 17/07/2025.
//

import SwiftUI

struct ContextCategoryView: View {
    let familyId: String
    let category: ContextCategory
    let insightCount: Int
    
    @Environment(\.dismiss) private var dismiss
    @State private var insights: [ContextualInsight] = []
    @State private var isLoading = true
    @State private var hasError = false
    @State private var showingDeleteAlert = false
    @State private var insightToDelete: ContextualInsight?
    
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
                    
                    VStack(spacing: 2) {
                        Text(category.displayName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(ColorPalette.white.opacity(0.9))
                        
                        if !insights.isEmpty {
                            Text("\(insights.count) insight\(insights.count == 1 ? "" : "s")")
                                .font(.system(size: 12))
                                .foregroundColor(ColorPalette.white.opacity(0.6))
                        }
                    }
                    
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
                } else if insights.isEmpty {
                    emptyView
                } else {
                    insightListView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                await loadInsights()
            }
        }
        .alert("Delete Insight", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let insight = insightToDelete {
                    Task {
                        await deleteInsight(insight)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this insight? This action cannot be undone.")
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
            Text(String(localized: "error.loading.insights"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(String(localized: "error.tryAgainLater"))
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
            
            Button(String(localized: "common.button.retry")) {
                Task {
                    await loadInsights()
                }
            }
            .foregroundColor(ColorPalette.terracotta)
            .font(.system(size: 16, weight: .medium))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: category.iconName)
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.3))
            
            Text(String(localized: "context.empty.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(String(localized: "context.empty.description", defaultValue: "Insights will appear here as you add situations that relate to \(category.displayName.lowercased())"))
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var insightListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(insights, id: \.id) { insight in
                    ContextInsightCard(
                        insight: insight,
                        onDelete: {
                            insightToDelete = insight
                            showingDeleteAlert = true
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100) // Space for tab bar
        }
    }
    
    @MainActor
    private func loadInsights() async {
        isLoading = true
        hasError = false
        
        do {
            insights = try await ContextualInsightService.shared.getInsightsByCategory(
                familyId: familyId,
                category: category
            )
            print("✅ Loaded \(insights.count) insights for category: \(category.displayName)")
        } catch {
            print("❌ Failed to load insights for category: \(error)")
            hasError = true
        }
        
        isLoading = false
    }
    
    @MainActor
    private func deleteInsight(_ insight: ContextualInsight) async {
        do {
            try await ContextualInsightService.shared.deleteInsight(id: insight.id)
            insights.removeAll { $0.id == insight.id }
            print("✅ Deleted insight: \(insight.id)")
        } catch {
            print("❌ Failed to delete insight: \(error)")
        }
    }
}

#Preview {
    ContextCategoryView(
        familyId: "preview-family-id",
        category: .familyContext,
        insightCount: 5
    )
}
