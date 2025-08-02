//
//  DeletedFlexibilitySocialView.swift
//  ParentGuidance
//
//  Created by alex kerss on 30/07/2025.
//

import SwiftUI

struct DeletedFlexibilitySocialView: View {
    let familyId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var deletedInsights: [DeletedFlexibilitySocialInsight] = []
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
                        Text(String(localized: "regulation.deleted.flexibility.title"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(SemanticColors.primaryText)
                        
                        if !deletedInsights.isEmpty {
                            Text(String(localized: "regulation.deleted.flexibility.count", defaultValue: "\(deletedInsights.count) item\(deletedInsights.count == 1 ? "" : "s")"))
                                .font(.system(size: 14))
                                .foregroundColor(SemanticColors.secondaryText)
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
                    insightsListView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SemanticColors.primaryBackground)
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                await loadDeletedInsights()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .foregroundColor(SemanticColors.secondaryText)
            
            Text(String(localized: "regulation.archive.loading"))
                .font(.system(size: 16))
                .foregroundColor(SemanticColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(SemanticColors.primaryText.opacity(0.4))
            
            Text(String(localized: "regulation.archive.error.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            Text(errorMessage.isEmpty ? String(localized: "error.tryAgainLater") : errorMessage)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(String(localized: "common.button.retry")) {
                Task {
                    await loadDeletedInsights()
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
            Image(systemName: "archivebox")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(SemanticColors.primaryText.opacity(0.4))
            
            Text(String(localized: "regulation.deleted.flexibility.empty.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            Text(String(localized: "regulation.deleted.flexibility.empty.description"))
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
    
    private var insightsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(deletedInsights, id: \.id) { deletedInsight in
                    DeletedFlexibilitySocialCard(
                        deletedInsight: deletedInsight,
                        onRestore: {
                            Task {
                                await restoreInsight(deletedInsight)
                            }
                        },
                        onPermanentDelete: {
                            Task {
                                await permanentlyDeleteInsight(deletedInsight)
                            }
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
        errorMessage = ""
        
        do {
            deletedInsights = try await ContextualInsightService.shared.getDeletedFlexibilitySocialInsights(familyId: familyId)
            print("✅ Loaded \(deletedInsights.count) deleted flexibility social insights")
        } catch {
            print("❌ Failed to load deleted flexibility social insights: \(error)")
            hasError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    private func restoreInsight(_ deletedInsight: DeletedFlexibilitySocialInsight) async {
        do {
            try await ContextualInsightService.shared.restoreDeletedFlexibilitySocialInsight(id: deletedInsight.id.uuidString)
            deletedInsights.removeAll { $0.id == deletedInsight.id }
            print("✅ Restored flexibility social insight: \(deletedInsight.id)")
        } catch {
            print("❌ Failed to restore flexibility social insight: \(error)")
            // Could show an error alert here if needed
        }
    }
    
    @MainActor
    private func permanentlyDeleteInsight(_ deletedInsight: DeletedFlexibilitySocialInsight) async {
        do {
            try await ContextualInsightService.shared.permanentlyDeleteFlexibilitySocialInsight(id: deletedInsight.id.uuidString)
            deletedInsights.removeAll { $0.id == deletedInsight.id }
            print("✅ Permanently deleted flexibility social insight: \(deletedInsight.id)")
        } catch {
            print("❌ Failed to permanently delete flexibility social insight: \(error)")
            // Could show an error alert here if needed
        }
    }
}

#Preview {
    DeletedFlexibilitySocialView(familyId: "preview-family-id")
}
