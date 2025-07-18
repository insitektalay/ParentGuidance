//
//  RegulationCategoryView.swift
//  ParentGuidance
//
//  Created by alex kerss on 18/07/2025.
//

import SwiftUI

struct RegulationCategoryView: View {
    let familyId: String
    let category: RegulationCategory
    let insightCount: Int
    
    @Environment(\.dismiss) private var dismiss
    @State private var insights: [ChildRegulationInsight] = []
    @State private var isLoading = true
    @State private var hasError = false
    @State private var errorMessage = ""
    
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
                    
                    VStack(spacing: 4) {
                        Text(category.parentFriendlyName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(ColorPalette.white.opacity(0.9))
                        
                        if insightCount > 0 {
                            Text("\(insightCount) insight\(insightCount == 1 ? "" : "s")")
                                .font(.system(size: 14))
                                .foregroundColor(ColorPalette.white.opacity(0.7))
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
            
            Text(errorMessage.isEmpty ? "Please try again later" : errorMessage)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await loadInsights()
                }
            }
            .foregroundColor(ColorPalette.terracotta)
            .font(.system(size: 16, weight: .medium))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: category.iconName)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(ColorPalette.white.opacity(0.4))
            
            Text("No patterns identified yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text("Insights for \(category.parentFriendlyName.lowercased()) will appear here as you add more situations.")
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
    
    private var insightListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(insights, id: \.id) { insight in
                    RegulationInsightCard(insight: insight) {
                        Task {
                            await deleteInsight(insight)
                        }
                    }
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
        errorMessage = ""
        
        do {
            insights = try await ContextualInsightService.shared.getChildRegulationInsights(
                familyId: familyId,
                category: category
            )
            print("✅ Loaded \(insights.count) regulation insights for category: \(category.parentFriendlyName)")
        } catch {
            print("❌ Failed to load regulation insights: \(error)")
            hasError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    private func deleteInsight(_ insight: ChildRegulationInsight) async {
        do {
            try await ContextualInsightService.shared.deleteChildRegulationInsight(id: insight.id.uuidString)
            insights.removeAll { $0.id == insight.id }
            print("✅ Deleted regulation insight: \(insight.id)")
        } catch {
            print("❌ Failed to delete regulation insight: \(error)")
            // Could show an error alert here if needed
        }
    }
}

#Preview {
    RegulationCategoryView(
        familyId: "preview-family-id",
        category: .core,
        insightCount: 5
    )
}
