//
//  DeletedCopingStrategiesView.swift
//  ParentGuidance
//
//  Created by alex kerss on 30/07/2025.
//

import SwiftUI

struct DeletedCopingStrategiesView: View {
    let familyId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var deletedStrategies: [DeletedCopingStrategy] = []
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
                            .foregroundColor(ColorPalette.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    // Delete All button - only show when there are items
                    if !deletedStrategies.isEmpty {
                        Button(action: {
                            showingDeleteAllAlert = true
                        }) {
                            Text(String(localized: "regulation.archive.button.deleteAll"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(ColorPalette.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(ColorPalette.terracotta)
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
                    Text(String(localized: "regulation.deleted.coping.title"))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    if !deletedStrategies.isEmpty {
                        Text("\(deletedStrategies.count) item\(deletedStrategies.count == 1 ? "" : "s")")
                            .font(.system(size: 14))
                            .foregroundColor(ColorPalette.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Content
                if isLoading {
                    loadingView
                } else if hasError {
                    errorView
                } else if deletedStrategies.isEmpty {
                    emptyView
                } else {
                    strategiesListView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                await loadDeletedStrategies()
            }
        }
        .alert(String(localized: "regulation.archive.deleteAll.title"), isPresented: $showingDeleteAllAlert) {
            Button(String(localized: "common.cancel"), role: .cancel) { }
            Button(String(localized: "regulation.archive.deleteAll.confirm"), role: .destructive) {
                Task {
                    await deleteAllStrategies()
                }
            }
        } message: {
            Text(String(localized: "regulation.archive.deleteAll.message \(deletedStrategies.count)"))
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .foregroundColor(ColorPalette.white.opacity(0.8))
            
            Text(String(localized: "regulation.archive.loading"))
                .font(.system(size: 16))
                .foregroundColor(ColorPalette.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(ColorPalette.white.opacity(0.4))
            
            Text(String(localized: "regulation.archive.error.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(errorMessage.isEmpty ? String(localized: "error.tryAgainLater") : errorMessage)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button(String(localized: "common.button.retry")) {
                Task {
                    await loadDeletedStrategies()
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
            Image(systemName: "archivebox")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(ColorPalette.white.opacity(0.4))
            
            Text(String(localized: "regulation.deleted.coping.empty.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(String(localized: "regulation.deleted.coping.empty.description"))
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
    
    private var strategiesListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(deletedStrategies, id: \.id) { deletedStrategy in
                    DeletedCopingStrategyCard(
                        deletedStrategy: deletedStrategy,
                        onRestore: {
                            Task {
                                await restoreStrategy(deletedStrategy)
                            }
                        },
                        onPermanentDelete: {
                            Task {
                                await permanentlyDeleteStrategy(deletedStrategy)
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
    private func loadDeletedStrategies() async {
        isLoading = true
        hasError = false
        errorMessage = ""
        
        do {
            deletedStrategies = try await ContextualInsightService.shared.getDeletedCopingStrategies(familyId: familyId)
            print("✅ Loaded \(deletedStrategies.count) deleted coping strategies")
        } catch {
            print("❌ Failed to load deleted coping strategies: \(error)")
            hasError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    private func restoreStrategy(_ deletedStrategy: DeletedCopingStrategy) async {
        do {
            try await ContextualInsightService.shared.restoreDeletedCopingStrategy(id: deletedStrategy.id.uuidString)
            deletedStrategies.removeAll { $0.id == deletedStrategy.id }
            print("✅ Restored coping strategy: \(deletedStrategy.id)")
        } catch {
            print("❌ Failed to restore coping strategy: \(error)")
            // Could show an error alert here if needed
        }
    }
    
    @MainActor
    private func permanentlyDeleteStrategy(_ deletedStrategy: DeletedCopingStrategy) async {
        do {
            try await ContextualInsightService.shared.permanentlyDeleteCopingStrategy(id: deletedStrategy.id.uuidString)
            deletedStrategies.removeAll { $0.id == deletedStrategy.id }
            print("✅ Permanently deleted coping strategy: \(deletedStrategy.id)")
        } catch {
            print("❌ Failed to permanently delete coping strategy: \(error)")
            // Could show an error alert here if needed
        }
    }
    
    @MainActor
    private func deleteAllStrategies() async {
        do {
            try await ContextualInsightService.shared.permanentlyDeleteAllDeletedCopingStrategies(familyId: familyId)
            deletedStrategies.removeAll()
            print("✅ Successfully deleted all coping strategies")
        } catch {
            print("❌ Failed to delete all coping strategies: \(error)")
        }
    }
}

#Preview {
    DeletedCopingStrategiesView(familyId: "preview-family-id")
}