//
//  LibraryView.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/06/2025.
//

import SwiftUI

struct LibraryView: View {
    @StateObject private var controller = LibraryViewController()
    @ObservedObject private var selectionManager: LibrarySelectionManager
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var showingContextualKnowledgeBase = false
    
    init() {
        let controller = LibraryViewController()
        self._controller = StateObject(wrappedValue: controller)
        self.selectionManager = controller.selectionManager
    }
    
    var body: some View {
        NavigationStack {
            if selectionManager.isGeneratingFramework {
                FrameworkGeneratingView()
            } else if let selectedSituation = controller.selectedSituation {
                SituationDetailView(
                    situation: selectedSituation,
                    guidance: controller.selectedGuidance,
                    isLoadingGuidance: controller.isLoadingGuidance,
                    guidanceError: controller.guidanceError,
                    onBack: {
                        controller.clearSelection()
                    }
                )
            } else {
                libraryListView
            }
        }
        .onAppear {
            controller.currentUserId = appCoordinator.currentUserId
            if controller.situations.isEmpty {
                controller.loadSituations()
            }
        }
        .sheet(isPresented: $showingContextualKnowledgeBase) {
            if let familyId = appCoordinator.currentUserId {
                ContextualKnowledgeBaseView(familyId: familyId)
            }
        }
    }
    
    private var libraryListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Library header with search, filters, and sorting
                headerSection
                
                // Foundation tool card
                foundationToolSection
                
                // Your Child's World card
                yourChildsWorldSection
                
                // Selection header (when in selection mode)
                if selectionManager.isInSelectionMode {
                    selectionHeader
                }
                
                // Dynamic content based on controller state
                dynamicContentSection
            }
            .padding(.top, 16)
            .padding(.bottom, 100) // Space for tab bar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .refreshable {
            controller.refreshSituations()
        }
        .overlay(sortDropdownOverlay)
        .overlay(deleteConfirmationOverlay)
    }
    
    private var headerSection: some View {
        LibraryHeaderView(controller: controller)
    }
    
    private var foundationToolSection: some View {
        FoundationToolCard(
            familyId: appCoordinator.currentUserId,
            onViewTools: {
                print("View tools tapped")
            },
            onSetupFramework: {
                print("Set Up Framework tapped - entering selection mode")
                selectionManager.enterSelectionMode()
                print("Selection mode state: \(selectionManager.isInSelectionMode)")
            }
        )
        .padding(.horizontal, 16)
    }
    
    private var yourChildsWorldSection: some View {
        YourChildsWorldCard(
            familyId: appCoordinator.currentUserId,
            onViewInsights: {
                print("View insights tapped")
                showingContextualKnowledgeBase = true
            }
        )
        .padding(.horizontal, 16)
    }
    
    private var selectionHeader: some View {
        HStack(spacing: 12) {
            Text(selectionManager.selectionCountText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorPalette.white)
            
            Spacer()
            
            Button("Cancel") {
                selectionManager.exitSelectionMode()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(ColorPalette.white.opacity(0.8))
            
            Button("Generate Framework") {
                print("Generate Framework tapped - placeholder for Step 5")
                selectionManager.handleGenerateFrameworkTap()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(ColorPalette.terracotta)
            .disabled(!selectionManager.canGenerateFramework)
            .opacity(selectionManager.canGenerateFramework ? 1.0 : 0.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(ColorPalette.navy.opacity(0.3))
        .overlay(
            Rectangle()
                .fill(ColorPalette.white.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var dynamicContentSection: some View {
        Group {
            switch controller.viewState {
            case .loading:
                loadingView
                    
            case .error:
                errorView
                    
            case .empty:
                emptyView
                    
            case .content:
                contentView
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .foregroundColor(ColorPalette.white.opacity(0.8))
            
            Text("Loading your situations...")
                .font(.system(size: 16))
                .foregroundColor(ColorPalette.white.opacity(0.7))
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Text("Unable to load situations")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(controller.errorMessage)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                controller.retry()
            }
            .foregroundColor(ColorPalette.terracotta)
            .font(.system(size: 16, weight: .medium))
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Text("No situations yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text("Start by adding your first parenting situation in the New tab")
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
    
    private var contentView: some View {
        Group {
            if controller.searchQuery.isEmpty {
                groupedSituationsView
            } else {
                searchResultsView
            }
        }
    }
    
    private var groupedSituationsView: some View {
        ForEach(controller.groupedSituations, id: \.title) { group in
            VStack(alignment: .leading, spacing: 12) {
                Text(group.title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ColorPalette.white.opacity(0.9))
                    .padding(.horizontal, 16)
                
                VStack(spacing: 12) {
                    ForEach(group.situations, id: \.id) { situation in
                        SituationCard(
                            situation: situation,
                            selectionManager: selectionManager,
                            onTap: {
                                controller.selectSituation(situation)
                            },
                            onToggleFavorite: {
                                controller.toggleFavorite(id: situation.id)
                            },
                            onDelete: {
                                controller.deleteSituation(id: situation.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Results (\(controller.filteredSituations.count))")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .padding(.horizontal, 16)
            
            if controller.filteredSituations.isEmpty {
                VStack(spacing: 16) {
                    Text("No situations found")
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                    
                    Text("Try a different search term")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.5))
                }
                .padding(40)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    ForEach(controller.filteredSituations, id: \.id) { situation in
                        SituationCard(
                            situation: situation,
                            selectionManager: selectionManager,
                            onTap: {
                                controller.selectSituation(situation)
                            },
                            onToggleFavorite: {
                                controller.toggleFavorite(id: situation.id)
                            },
                            onDelete: {
                                controller.deleteSituation(id: situation.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var sortDropdownOverlay: some View {
        Group {
            if controller.isShowingSortDropdown {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: {
                                controller.updateSort(option)
                                controller.toggleSortDropdown()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: option.sfSymbol)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ColorPalette.white)
                                        .frame(width: 16)
                                    
                                    Text(option.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ColorPalette.white)
                                    
                                    Spacer()
                                    
                                    if controller.selectedSort == option {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(ColorPalette.terracotta)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    controller.selectedSort == option 
                                        ? ColorPalette.terracotta.opacity(0.1)
                                        : Color.clear
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if option != SortOption.allCases.last {
                                Divider()
                                    .background(ColorPalette.white.opacity(0.1))
                            }
                        }
                    }
                    .background(ColorPalette.navy)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ColorPalette.white.opacity(0.2), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .frame(width: 180)
                    .position(
                        x: geometry.size.width - 100, // Position near right edge
                        y: 120 // Position below header area
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
                .onTapGesture {
                    controller.toggleSortDropdown()
                }
                .zIndex(1000)
            }
        }
    }
    
    private var deleteConfirmationOverlay: some View {
        Group {
            if controller.showingDeleteConfirmation {
                ZStack {
                    // Semi-transparent background
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            controller.cancelDelete()
                        }
                    
                    // Confirmation dialog
                    ConfirmationDialog(
                        title: "Delete Situation",
                        message: "Are you sure you want to delete this situation? This action cannot be undone and will also remove any associated guidance.",
                        onDestruct: {
                            controller.confirmDelete()
                        },
                        onCancel: {
                            controller.cancelDelete()
                        }
                    )
                }
                .zIndex(2000) // Higher than sort dropdown
            }
        }
    }
    
}

#Preview {
    LibraryView()
}
