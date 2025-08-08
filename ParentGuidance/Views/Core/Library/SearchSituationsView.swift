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
    @ObservedObject var controller: LibraryViewController
    @StateObject private var regenerationService = ManualRegenerationService.shared
    @State private var shouldDismiss = false
    @State private var hasEnteredSelectionMode = false
    @State private var guidanceStatus: [String: Bool] = [:]
    
    init(familyId: String, selectionManager: LibrarySelectionManager, controller: LibraryViewController, isSelectionMode: Bool = false) {
        self.familyId = familyId
        self.selectionManager = selectionManager
        self.isSelectionMode = isSelectionMode
        self.controller = controller
        
        // Ensure controller is set up for this family
        controller.currentUserId = familyId
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
                    },
                    onDateUpdated: {
                        controller.refreshSituations()
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
            
            // Check regeneration status
            Task {
                if let familyUUID = UUID(uuidString: familyId) {
                    try? await regenerationService.checkRegenerationStatus(familyId: familyUUID)
                }
                
                // Check guidance status for all situations
                await checkGuidanceStatus()
            }
            
            // Enter selection mode if needed, but only once
            if isSelectionMode && !hasEnteredSelectionMode {
                hasEnteredSelectionMode = true
                // Only enter selection mode if it's not already active
                if !selectionManager.isInSelectionMode {
                    DispatchQueue.main.async {
                        selectionManager.enterSelectionMode()
                    }
                } else {
                    print("📋 Selection mode already active - using existing state")
                }
            }
        }
        .onReceive(selectionManager.$isGeneratingFramework) { isGenerating in
            if !isGenerating && shouldDismiss {
                dismiss()
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
                            .foregroundColor(SemanticColors.primaryText)
                    }
                    
                    Spacer()
                    
                    Text(isSelectionMode ? String(localized: "library.search.selectTitle") : String(localized: "library.search.title"))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                // Search Header with Filters
                searchHeaderSection
            }
            .background(SemanticColors.primaryBackground)
            
            // Scrollable Content
            ScrollViewReader { scrollProxy in
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
                .background(SemanticColors.primaryBackground)
                .refreshable {
                    controller.refreshSituations()
                }
                .onAppear {
                    // Check if we should restore scroll position when view appears
                    if controller.shouldRestoreScrollPosition, let scrollPosition = controller.savedScrollPosition {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                scrollProxy.scrollTo(scrollPosition, anchor: .center)
                            }
                            controller.shouldRestoreScrollPosition = false
                        }
                    }
                }
                .onChange(of: controller.shouldRestoreScrollPosition) { shouldRestore in
                    if shouldRestore, let scrollPosition = controller.savedScrollPosition {
                        // Add a delay to ensure the view is ready
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                scrollProxy.scrollTo(scrollPosition, anchor: .center)
                            }
                            controller.shouldRestoreScrollPosition = false
                        }
                    }
                }
            }
            .overlay(sortDropdownOverlay)
            .overlay(deleteConfirmationOverlay)
            .overlay(frameworkGenerationOverlay)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SemanticColors.primaryBackground)
        .navigationBarHidden(true)
        .alert("Delete Failed", isPresented: $controller.showingDeleteError) {
            Button("OK") {
                controller.showingDeleteError = false
            }
        } message: {
            Text(controller.deleteErrorMessage)
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkGuidanceStatus() async {
        // Check guidance status for all current situations
        guidanceStatus.removeAll()
        
        for situation in controller.situations {
            let hasGuidance = !regenerationService.needsRegeneration(situationId: situation.id)
            await MainActor.run {
                guidanceStatus[situation.id] = hasGuidance
            }
        }
    }
    
    private func regenerateSituation(_ situation: Situation) async {
        do {
            // Get current regen run if any
            let regenRunId: UUID? = nil // This could come from Time Machine context
            
            try await regenerationService.regenerateGuidance(
                for: situation,
                regenRunId: regenRunId
            )
            
            // Update guidance status
            await MainActor.run {
                guidanceStatus[situation.id] = true
            }
            
            // Refresh the situation list to show updated guidance
            controller.refreshSituations()
            
        } catch RegenerationError.chronologicalOrderViolation(let message) {
            // Show alert about chronological order
            await MainActor.run {
                controller.errorMessage = message
                controller.viewState = .error
            }
        } catch {
            // Show general error
            await MainActor.run {
                controller.errorMessage = "Failed to regenerate guidance: \(error.localizedDescription)"
                controller.viewState = .error
            }
        }
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
                        .foregroundColor(SemanticColors.secondaryText)
                        .padding(8)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(SemanticColors.border, lineWidth: 1)
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
                .foregroundColor(SemanticColors.primaryText)
            
            Spacer()
            
            Button(String(localized: "common.cancel")) {
                selectionManager.exitSelectionMode()
                dismiss()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(SemanticColors.secondaryText)
            
            Button(String(localized: "library.selection.generateFramework")) {
                print("Generate Framework tapped - starting generation")
                shouldDismiss = true
                selectionManager.handleGenerateFrameworkTap()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(SemanticColors.accent)
            .disabled(!selectionManager.canGenerateFramework)
            .opacity(selectionManager.canGenerateFramework ? 1.0 : 0.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(SemanticColors.tertiaryBackground)
        .overlay(
            Rectangle()
                .fill(SemanticColors.border)
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
                .foregroundColor(SemanticColors.secondaryText)
            
            Text(String(localized: "library.search.loading"))
                .font(.system(size: 16))
                .foregroundColor(SemanticColors.secondaryText)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Text(String(localized: "library.search.error.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            Text(controller.errorMessage)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(String(localized: "common.tryAgain")) {
                controller.retry()
            }
            .foregroundColor(SemanticColors.accent)
            .font(.system(size: 16, weight: .medium))
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Text(String(localized: "library.search.empty.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            Text(String(localized: "library.search.empty.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.secondaryText)
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
                    .foregroundColor(SemanticColors.primaryText)
                    .padding(.horizontal, 16)
                
                VStack(spacing: 12) {
                    ForEach(group.situations, id: \.id) { situation in
                        RegeneratableSituationCard(
                            situation: situation,
                            hasGuidance: guidanceStatus[situation.id] ?? true,
                            isRegenerating: regenerationService.isRegenerating(situationId: situation.id),
                            selectionManager: selectionManager,
                            onTap: {
                                // Save scroll position before navigating
                                controller.savedScrollPosition = situation.id
                                controller.selectSituation(situation)
                            },
                            onToggleFavorite: {
                                controller.toggleFavorite(id: situation.id)
                            },
                            onDelete: {
                                controller.deleteSituation(id: situation.id)
                            },
                            onRegenerate: {
                                Task {
                                    await regenerateSituation(situation)
                                }
                            }
                        )
                        .id(situation.id) // Add ID for scroll position tracking
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
                .foregroundColor(SemanticColors.primaryText)
                .padding(.horizontal, 16)
            
            if controller.filteredSituations.isEmpty {
                VStack(spacing: 16) {
                    Text(String(localized: "library.search.noResults.title"))
                        .font(.system(size: 16))
                        .foregroundColor(SemanticColors.secondaryText)
                    
                    Text(String(localized: "library.search.noResults.subtitle"))
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.tertiaryText)
                }
                .padding(40)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    ForEach(controller.filteredSituations, id: \.id) { situation in
                        RegeneratableSituationCard(
                            situation: situation,
                            hasGuidance: guidanceStatus[situation.id] ?? true,
                            isRegenerating: regenerationService.isRegenerating(situationId: situation.id),
                            selectionManager: selectionManager,
                            onTap: {
                                // Save scroll position before navigating
                                controller.savedScrollPosition = situation.id
                                controller.selectSituation(situation)
                            },
                            onToggleFavorite: {
                                controller.toggleFavorite(id: situation.id)
                            },
                            onDelete: {
                                controller.deleteSituation(id: situation.id)
                            },
                            onRegenerate: {
                                Task {
                                    await regenerateSituation(situation)
                                }
                            }
                        )
                        .id(situation.id) // Add ID for scroll position tracking
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
                                        .foregroundColor(SemanticColors.primaryText)
                                        .frame(width: 16)
                                    
                                    Text(option.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(SemanticColors.primaryText)
                                    
                                    Spacer()
                                    
                                    if controller.selectedSort == option {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(SemanticColors.accent)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    controller.selectedSort == option 
                                        ? SemanticColors.accent.opacity(0.1)
                                        : Color.clear
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if option != SortOption.allCases.last {
                                Divider()
                                    .background(SemanticColors.border)
                            }
                        }
                    }
                    .background(SemanticColors.primaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(SemanticColors.border, lineWidth: 1)
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
    
    private var frameworkGenerationOverlay: some View {
        Group {
            if selectionManager.isGeneratingFramework {
                ZStack {
                    // Semi-transparent background
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    
                    // Generation progress card
                    VStack(spacing: 20) {
                        // Progress indicator
                        ProgressView()
                            .scaleEffect(1.5)
                            .foregroundColor(SemanticColors.accent)
                        
                        // Status text
                        VStack(spacing: 8) {
                            Text(String(localized: "library.framework.generating.title"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(SemanticColors.primaryText)
                                .multilineTextAlignment(.center)
                            
                            Text(String(localized: "library.framework.generating.subtitle"))
                                .font(.system(size: 14))
                                .foregroundColor(SemanticColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Selection count reminder
                        Text(selectionManager.selectionCountText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SemanticColors.accent.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(SemanticColors.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(24)
                    .background(SemanticColors.primaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(SemanticColors.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .padding(40)
                }
                .zIndex(3000) // Highest priority overlay
            }
        }
    }
}

#Preview {
    let selectionManager = LibrarySelectionManager()
    let controller = LibraryViewController()
    return SearchSituationsView(
        familyId: "preview-family-id",
        selectionManager: selectionManager,
        controller: controller,
        isSelectionMode: false
    )
}
