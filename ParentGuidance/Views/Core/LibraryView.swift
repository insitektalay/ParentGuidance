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
    @State private var showingRegulationInsights = false
    @State private var showingSearchSituations = false
    
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
        .sheet(isPresented: $showingRegulationInsights) {
            if let familyId = appCoordinator.currentUserId {
                RegulationInsightsView(familyId: familyId)
            }
        }
        .sheet(isPresented: $showingSearchSituations) {
            if let familyId = appCoordinator.currentUserId {
                SearchSituationsView(
                    familyId: familyId,
                    selectionManager: selectionManager,
                    isSelectionMode: selectionManager.isInSelectionMode
                )
            }
        }
    }
    
    private var libraryListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Search Situations card
                searchSituationsSection
                
                // Foundation tool card
                foundationToolSection
                
                // Noticing What Matters card
                noticingWhatMattersSection
                
                // Your Child's World card
                yourChildsWorldSection
                
                // Selection header (when in selection mode)
                if selectionManager.isInSelectionMode {
                    selectionHeader
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 100) // Space for tab bar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .refreshable {
            controller.refreshSituations()
        }
    }
    
    private var foundationToolSection: some View {
        FoundationToolCard(
            familyId: appCoordinator.currentUserId,
            onViewTools: {
                print("View tools tapped")
            },
            onSetupFramework: {
                print("Set Up Framework tapped - entering selection mode and navigating to search")
                selectionManager.enterSelectionMode()
                showingSearchSituations = true
            }
        )
        .padding(.horizontal, 16)
    }
    
    private var noticingWhatMattersSection: some View {
        NoticingWhatMattersCard(
            familyId: appCoordinator.currentUserId,
            onViewInsights: {
                print("View regulation insights tapped")
                showingRegulationInsights = true
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
    
    private var searchSituationsSection: some View {
        SearchSituationsCard(
            familyId: appCoordinator.currentUserId,
            onSearchSituations: {
                print("Search situations tapped")
                showingSearchSituations = true
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
            
            Button(String(localized: "common.cancel")) {
                selectionManager.exitSelectionMode()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(ColorPalette.white.opacity(0.8))
            
            Button(String(localized: "library.selection.generateFramework")) {
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
    
}

#Preview {
    LibraryView()
}
