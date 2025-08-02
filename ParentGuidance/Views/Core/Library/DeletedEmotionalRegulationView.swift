//
//  DeletedEmotionalRegulationView.swift
//  ParentGuidance
//
//  Created by alex kerss on 30/07/2025.
//

import SwiftUI

struct DeletedEmotionalRegulationView: View {
    let familyId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var deletedInsights: [DeletedEmotionalRegulationInsight] = []
    @State private var isLoading = true
    @State private var hasError = false
    @State private var errorMessage = ""
    @State private var showingDeleteAllAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header - Navigation Bar
                HStack(alignment: .center, spacing: 12) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(SemanticColors.primaryText)
                    }
                    
                    Spacer()
                    
                    // Delete All button - only show when there are items
                    if !deletedInsights.isEmpty {
                        Button(action: {
                            showingDeleteAllAlert = true
                        }) {
                            Text(String(localized: "regulation.archive.button.deleteAll"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SemanticColors.primaryText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(SemanticColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel(String(localized: "regulation.archive.button.deleteAll"))
                        .accessibilityHint(String(localized: "regulation.archive.deleteAll.hint"))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // Title Section
                VStack(spacing: 8) {
                    Text(String(localized: "regulation.deleted.emotional.title"))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(SemanticColors.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    if !deletedInsights.isEmpty {
                        Text(String(localized: "regulation.deleted.emotional.count", defaultValue: "\(deletedInsights.count) item\(deletedInsights.count == 1 ? "" : "s")"))
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.secondaryText)
                    }
                }
                .padding(.horizontal, 16)
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
        .alert(String(localized: "regulation.archive.deleteAll.title"), isPresented: $showingDeleteAllAlert) {
            Button(String(localized: "common.cancel"), role: .cancel) { }
            Button(String(localized: "regulation.archive.deleteAll.confirm"), role: .destructive) {
                Task {
                    await deleteAllInsights()
                }
            }
        } message: {
            Text(String(localized: "regulation.archive.deleteAll.message \(deletedInsights.count)"))
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
            
            Text(String(localized: "regulation.deleted.emotional.empty.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            Text(String(localized: "regulation.deleted.emotional.empty.description"))
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
                    DeletedEmotionalRegulationCard(
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
            deletedInsights = try await ContextualInsightService.shared.getDeletedEmotionalRegulationInsights(familyId: familyId)
            print("✅ Loaded \(deletedInsights.count) deleted emotional regulation insights")
        } catch {
            print("❌ Failed to load deleted emotional regulation insights: \(error)")
            hasError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    private func restoreInsight(_ deletedInsight: DeletedEmotionalRegulationInsight) async {
        do {
            try await ContextualInsightService.shared.restoreDeletedEmotionalRegulationInsight(id: deletedInsight.id.uuidString)
            deletedInsights.removeAll { $0.id == deletedInsight.id }
            print("✅ Restored emotional regulation insight: \(deletedInsight.id)")
        } catch {
            print("❌ Failed to restore emotional regulation insight: \(error)")
            // Could show an error alert here if needed
        }
    }
    
    @MainActor
    private func permanentlyDeleteInsight(_ deletedInsight: DeletedEmotionalRegulationInsight) async {
        do {
            try await ContextualInsightService.shared.permanentlyDeleteEmotionalRegulationInsight(id: deletedInsight.id.uuidString)
            deletedInsights.removeAll { $0.id == deletedInsight.id }
            print("✅ Permanently deleted emotional regulation insight: \(deletedInsight.id)")
        } catch {
            print("❌ Failed to permanently delete emotional regulation insight: \(error)")
            // Could show an error alert here if needed
        }
    }
    
    @MainActor
    private func deleteAllInsights() async {
        do {
            try await ContextualInsightService.shared.permanentlyDeleteAllDeletedEmotionalRegulationInsights(familyId: familyId)
            deletedInsights.removeAll()
            print("✅ Successfully deleted all emotional regulation insights")
        } catch {
            print("❌ Failed to delete all emotional regulation insights: \(error)")
        }
    }
}

#Preview {
    DeletedEmotionalRegulationView(familyId: "preview-family-id")
}