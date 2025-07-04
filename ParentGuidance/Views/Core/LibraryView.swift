//
//  LibraryView.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/06/2025.
//

import SwiftUI

struct LibraryView: View {
    @StateObject private var controller = LibraryViewController()
    
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
                libraryListView
            }
        }
    }
    
    private var libraryListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Search bar
                SearchBar(searchText: $controller.searchQuery)
                    .padding(.horizontal, 16)
                
                // Foundation tool card
                FoundationToolCard(
                    onViewTools: {
                        print("View tools tapped")
                    },
                    onManage: {
                        print("Manage tapped")
                    }
                )
                .padding(.horizontal, 16)
                
                // Dynamic content based on controller state
                switch controller.viewState {
                case .loading:
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
                    
                case .error:
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
                    
                case .empty:
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
                    
                case .content:
                    if controller.searchQuery.isEmpty {
                        // Show grouped view when not searching
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
                                            onTap: {
                                                controller.selectSituation(situation)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    } else {
                        // Show search results
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
                                            onTap: {
                                                controller.selectSituation(situation)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
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
}

#Preview {
    LibraryView()
}
