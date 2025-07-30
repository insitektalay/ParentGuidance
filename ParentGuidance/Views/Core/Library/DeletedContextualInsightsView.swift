//
//  DeletedContextualInsightsView.swift
//  ParentGuidance
//
//  Created by alex kerss on 30/07/2025.
//

import SwiftUI

struct DeletedContextualInsightsView: View {
    let familyId: String
    let category: ContextCategory?
    
    @Environment(\.dismiss) private var dismiss
    @State private var deletedInsights: [DeletedContextualInsight] = []
    @State private var isLoading = true
    @State private var hasError = false
    @State private var showingRestoreAlert = false
    @State private var showingPermanentDeleteAlert = false
    @State private var insightToRestore: DeletedContextualInsight?
    @State private var insightToPermanentlyDelete: DeletedContextualInsight?
    
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
                        if let category = category {
                            Text("Deleted \(category.displayName)")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(ColorPalette.white.opacity(0.9))
                        } else {
                            Text(String(localized: "library.deleted.contextual.title"))
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(ColorPalette.white.opacity(0.9))
                        }
                        
                        if !deletedInsights.isEmpty {
                            Text("\(deletedInsights.count) insight\(deletedInsights.count == 1 ? "" : "s")")
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
                } else if deletedInsights.isEmpty {
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
                await loadDeletedInsights()
            }
        }
        .alert("Restore Insight", isPresented: $showingRestoreAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Restore") {
                if let insight = insightToRestore {
                    Task {
                        await restoreInsight(insight)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to restore this insight? It will be moved back to your active insights.")
        }
        .alert("Permanently Delete", isPresented: $showingPermanentDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Forever", role: .destructive) {
                if let insight = insightToPermanentlyDelete {
                    Task {
                        await permanentlyDeleteInsight(insight)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to permanently delete this insight? This action cannot be undone.")
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .foregroundColor(ColorPalette.white.opacity(0.8))
            
            Text(String(localized: "library.deleted.loading"))
                .font(.system(size: 16))
                .foregroundColor(ColorPalette.white.opacity(0.7))
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Text(String(localized: "library.deleted.error.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(String(localized: "library.deleted.error.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
            
            Button(String(localized: "common.button.retry")) {
                Task {
                    await loadDeletedInsights()
                }
            }
            .foregroundColor(ColorPalette.terracotta)
            .font(.system(size: 16, weight: .medium))
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: category?.iconName ?? "trash")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.3))
            
            Text(String(localized: "library.deleted.empty.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(String(localized: "library.deleted.empty.description"))
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    private var insightListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(deletedInsights, id: \.id) { insight in
                    DeletedContextualInsightCard(
                        insight: insight,
                        onRestore: {
                            insightToRestore = insight
                            showingRestoreAlert = true
                        },
                        onPermanentDelete: {
                            insightToPermanentlyDelete = insight
                            showingPermanentDeleteAlert = true
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100) // Space for tab bar
        }
    }
    
    @MainActor
    private func loadDeletedInsights() async {
        isLoading = true
        hasError = false
        
        do {
            deletedInsights = try await ContextualInsightService.shared.getDeletedContextualInsights(
                familyId: familyId,
                category: category
            )
            print("✅ Loaded \(deletedInsights.count) deleted contextual insights")
        } catch {
            print("❌ Failed to load deleted contextual insights: \(error)")
            hasError = true
        }
        
        isLoading = false
    }
    
    @MainActor
    private func restoreInsight(_ insight: DeletedContextualInsight) async {
        do {
            try await ContextualInsightService.shared.restoreDeletedContextualInsight(id: insight.id.uuidString.lowercased())
            deletedInsights.removeAll { $0.id == insight.id }
            print("✅ Restored insight: \(insight.id)")
        } catch {
            print("❌ Failed to restore insight: \(error)")
        }
    }
    
    @MainActor
    private func permanentlyDeleteInsight(_ insight: DeletedContextualInsight) async {
        do {
            try await ContextualInsightService.shared.permanentlyDeleteContextualInsight(id: insight.id.uuidString.lowercased())
            deletedInsights.removeAll { $0.id == insight.id }
            print("✅ Permanently deleted insight: \(insight.id)")
        } catch {
            print("❌ Failed to permanently delete insight: \(error)")
        }
    }
}

#Preview {
    DeletedContextualInsightsView(
        familyId: "preview-family-id",
        category: .familyContext
    )
}
