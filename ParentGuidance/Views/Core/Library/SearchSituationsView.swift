//
//  SearchSituationsView.swift
//  ParentGuidance
//
//  Created by alex kerss on 18/07/2025.
//

import SwiftUI

struct SearchSituationsView: View {
    let familyId: String
    let selectionManager: LibrarySelectionManager
    let isSelectionMode: Bool
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var controller: LibraryViewController
    
    init(familyId: String, selectionManager: LibrarySelectionManager, isSelectionMode: Bool = false) {
        self.familyId = familyId
        self.selectionManager = selectionManager
        self.isSelectionMode = isSelectionMode
        
        // Create controller and set it up for this family
        let controller = LibraryViewController()
        controller.currentUserId = familyId
        self._controller = StateObject(wrappedValue: controller)
        
        // Enter selection mode if needed
        if isSelectionMode {
            selectionManager.enterSelectionMode()
        }
    }
    
    var body: some View {
        NavigationStack {
            if let selectedSituation = controller.selectedSituation {
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
                searchView
            }
        }
        .onAppear {
            controller.currentUserId = familyId
            if controller.situations.isEmpty {
                controller.loadSituations()
            }
        }
    }
    
    private var searchView: some View {
        VStack(spacing: 0) {
            // Fixed Header - Navigation + Search + Filters
            VStack(spacing: 0) {
                // Navigation Header
                HStack(alignment: .center, spacing: 12) {
                    Button(action: {
                        if isSelectionMode {
                            selectionManager.exitSelectionMode()
                        }
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(ColorPalette.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Text(isSelectionMode ? String(localized: "library.search.selectTitle") : String(localized: "library.search.title"))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                // Search Header with Filters
                searchHeaderSection
            }
            .background(ColorPalette.navy)
            
            // Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .navigationBarHidden(true)
    }
    
    private var searchHeaderSection: some View {
        VStack(spacing: 12) {
            // Search bar
            SearchBar(searchText: $controller.searchQuery)
                .padding(.horizontal, 16)
            
            // Filter and sort row
            HStack(spacing: 8) {
                // Date filter buttons (takes most space)
                SearchFilterView(controller: controller)
                
                // Sort dropdown button only 
                Button(action: {
                    controller.toggleSortDropdown()
                }) {
                    Image(systemName: controller.isShowingSortDropdown ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.8))
                        .padding(8)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ColorPalette.white.opacity(0.2), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 16)
            }
        }
    }
    
    private var selectionHeader: some View {
        HStack(spacing: 12) {
            Text(selectionManager.selectionCountText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorPalette.white)
            
            Spacer()
            
            Button(String(localized: "common.cancel")) {
                selectionManager.exitSelectionMode()
                dismiss()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(ColorPalette.white.opacity(0.8))
            
            Button(String(localized: "library.selection.generateFramework")) {
                print("Generate Framework tapped - placeholder for Step 5")
                selectionManager.handleGenerateFrameworkTap()
                dismiss()
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
            
            Text(String(localized: "library.search.loading"))
                .font(.system(size: 16))
                .foregroundColor(ColorPalette.white.opacity(0.7))
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Text(String(localized: "library.search.error.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(controller.errorMessage)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button(String(localized: "common.tryAgain")) {
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
            Text(String(localized: "library.search.empty.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(String(localized: "library.search.empty.subtitle"))
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
            Text(String(localized: "library.search.results \(controller.filteredSituations.count)"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .padding(.horizontal, 16)
            
            if controller.filteredSituations.isEmpty {
                VStack(spacing: 16) {
                    Text(String(localized: "library.search.noResults.title"))
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                    
                    Text(String(localized: "library.search.noResults.subtitle"))
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
                        title: String(localized: "library.delete.title"),
                        message: String(localized: "library.delete.message"),
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
    let selectionManager = LibrarySelectionManager()
    return SearchSituationsView(
        familyId: "preview-family-id",
        selectionManager: selectionManager,
        isSelectionMode: false
    )
}
