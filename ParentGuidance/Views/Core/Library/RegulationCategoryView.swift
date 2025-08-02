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
                            .foregroundColor(SemanticColors.primaryText)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text(category.parentFriendlyName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(SemanticColors.primaryText)
                        
                        if insightCount > 0 {
                            Text("\(insightCount) insight\(insightCount == 1 ? "" : "s")")
                                .font(.system(size: 14))
                                .foregroundColor(SemanticColors.secondaryText)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                // Deleted items navigation for all categories
                HStack {
                    Spacer()
                    
                    switch category {
                    case .copingStrategies:
                        NavigationLink(destination: DeletedCopingStrategiesView(familyId: familyId)) {
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
                        .accessibilityHint("Double tap to view deleted coping strategies")
                        
                    case .core:
                        NavigationLink(destination: DeletedEmotionalRegulationView(familyId: familyId)) {
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
                        .accessibilityHint("Double tap to view deleted emotional regulation insights")
                        
                    case .adhd:
                        NavigationLink(destination: DeletedAttentionFocusView(familyId: familyId)) {
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
                        .accessibilityHint("Double tap to view deleted attention and focus insights")
                        
                    case .mildAutism:
                        NavigationLink(destination: DeletedFlexibilitySocialView(familyId: familyId)) {
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
                        .accessibilityHint("Double tap to view deleted flexibility and social insights")
                    }
                }
                .padding(.horizontal, 16)
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
            .background(SemanticColors.primaryBackground)
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
                .foregroundColor(SemanticColors.secondaryText)
            
            Text("Loading insights...")
                .font(.system(size: 16))
                .foregroundColor(SemanticColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Text(String(localized: "error.loading.insights"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            Text(errorMessage.isEmpty ? String(localized: "error.tryAgainLater") : errorMessage)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(String(localized: "common.button.retry")) {
                Task {
                    await loadInsights()
                }
            }
            .foregroundColor(SemanticColors.accent)
            .font(.system(size: 16, weight: .medium))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: category.iconName)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(SemanticColors.primaryText.opacity(0.4))
            
            Text(String(localized: "regulation.empty.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            Text(String(localized: "regulation.empty.description", defaultValue: "Insights for \(category.parentFriendlyName.lowercased()) will appear here as you add more situations."))
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.secondaryText)
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
