//
//  LibraryViewController.swift
//  ParentGuidance
//
//  Created by alex kerss on 04/07/2025.
//

import Foundation
import SwiftUI

class LibraryViewController: ObservableObject {
    @Published var viewState: ViewState = .loading
    @Published var situations: [Situation] = []
    @Published var filteredSituations: [Situation] = []
    @Published var groupedSituations: [SituationGroup] = []
    @Published var searchQuery: String = "" {
        didSet {
            debounceSearch()
        }
    }
    @Published var errorMessage: String = ""
    
    // Filter state
    @Published var selectedDateFilter: DateFilter = .allTime
    @Published var selectedSort: SortOption = .mostRecent
    @Published var selectedCategories: Set<CategoryFilter> = []
    
    // UI state
    @Published var isShowingSortDropdown: Bool = false
    
    // Delete confirmation state
    @Published var showingDeleteConfirmation: Bool = false
    @Published var situationToDelete: String?
    
    // Search debouncing
    private var searchDebounceTimer: Timer?
    
    // Computed properties
    var activeFiltersCount: Int {
        var count = 0
        if selectedDateFilter != .allTime { count += 1 }
        if selectedSort != .mostRecent { count += 1 }
        if !selectedCategories.isEmpty { count += selectedCategories.count }
        return count
    }
    
    var dateFilterCounts: [DateFilter: Int] {
        var counts: [DateFilter: Int] = [:]
        
        for filter in DateFilter.allCases {
            counts[filter] = filter.filterSituations(situations).count
        }
        
        return counts
    }
    
    // Navigation state
    @Published var selectedSituation: Situation?
    @Published var selectedGuidance: [Guidance] = []
    @Published var isLoadingGuidance: Bool = false
    @Published var guidanceError: String?
    
    enum ViewState {
        case loading
        case error
        case empty
        case content
    }
    
    init() {
        loadSituations()
    }
    
    func loadSituations() {
        viewState = .loading
        
        Task {
            do {
                let userId = "15359b56-cabf-4b6a-9d2a-a3b11001b8e2"
                let userProfile = try await AuthService.shared.loadUserProfile(userId: userId)
                
                guard let familyId = userProfile.familyId else {
                    print("❌ No family_id found for user")
                    await MainActor.run {
                        self.viewState = .empty
                    }
                    return
                }
                
                print("📚 Loading all situations for family: \(familyId)")
                let allSituations = try await ConversationService.shared.getAllSituations(familyId: familyId)
                
                await MainActor.run {
                    self.situations = allSituations
                    self.viewState = allSituations.isEmpty ? .empty : .content
                    // Apply current filters to newly loaded situations
                    self.filterSituations()
                }
                
            } catch {
                print("❌ Error loading situations: \(error)")
                await MainActor.run {
                    self.errorMessage = "Failed to load situations. Please try again."
                    self.viewState = .error
                }
            }
        }
    }
    
    func retry() {
        loadSituations()
    }
    
    func refreshSituations() {
        loadSituations()
    }
    
    // MARK: - Search Debouncing
    private func debounceSearch() {
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            Task { @MainActor in
                self.performSearch()
            }
        }
    }
    
    private func performSearch() {
        filterSituations()
    }
    
    private func filterSituations() {
        var result = situations
        
        // Apply date filter
        result = selectedDateFilter.filterSituations(result)
        
        // Apply category filters
        if !selectedCategories.isEmpty {
            result = result.filter { situation in
                selectedCategories.contains { category in
                    category.matchesSituation(situation)
                }
            }
        }
        
        // Apply search query
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            result = result.filter { situation in
                situation.title.lowercased().contains(trimmedQuery.lowercased()) ||
                situation.description.lowercased().contains(trimmedQuery.lowercased())
            }
        }
        
        // Don't apply sorting here - let updateGroupedSituations handle it
        filteredSituations = result
        
        // Update grouped situations (this will apply sorting)
        updateGroupedSituations()
    }
    
    // MARK: - Date Grouping Foundation
    struct SituationGroup {
        let title: String
        let situations: [Situation]
    }
    
    private func updateGroupedSituations() {
        // First, apply sorting to the filtered situations
        let sortedSituations = selectedSort.sortSituations(filteredSituations)
        
        let calendar = Calendar.current
        let now = Date()
        
        var todayGroup: [Situation] = []
        var yesterdayGroup: [Situation] = []
        var thisWeekGroup: [Situation] = []
        var olderGroup: [Situation] = []
        
        // Group the sorted situations by date, preserving the sort order
        for situation in sortedSituations {
            guard let date = ISO8601DateFormatter().date(from: situation.createdAt) else {
                olderGroup.append(situation)
                continue
            }
            
            if calendar.isDateInToday(date) {
                todayGroup.append(situation)
            } else if calendar.isDateInYesterday(date) {
                yesterdayGroup.append(situation)
            } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
                thisWeekGroup.append(situation)
            } else {
                olderGroup.append(situation)
            }
        }
        
        // Don't re-sort - we already sorted before grouping
        
        var groups: [SituationGroup] = []
        
        if !todayGroup.isEmpty {
            groups.append(SituationGroup(title: "Today", situations: todayGroup))
        }
        if !yesterdayGroup.isEmpty {
            groups.append(SituationGroup(title: "Yesterday", situations: yesterdayGroup))
        }
        if !thisWeekGroup.isEmpty {
            groups.append(SituationGroup(title: "This Week", situations: thisWeekGroup))
        }
        if !olderGroup.isEmpty {
            groups.append(SituationGroup(title: "Older", situations: olderGroup))
        }
        
        groupedSituations = groups
        
    }
    
    // MARK: - Navigation & Guidance Loading
    func selectSituation(_ situation: Situation) {
        selectedSituation = situation
        loadGuidanceForSituation(situationId: situation.id)
    }
    
    func clearSelection() {
        selectedSituation = nil
        selectedGuidance = []
        guidanceError = nil
    }
    
    private func loadGuidanceForSituation(situationId: String) {
        isLoadingGuidance = true
        guidanceError = nil
        
        Task {
            do {
                print("📋 Loading guidance for situation: \(situationId)")
                let guidance = try await ConversationService.shared.getGuidanceForSituation(situationId: situationId)
                
                await MainActor.run {
                    self.selectedGuidance = guidance
                    self.isLoadingGuidance = false
                    
                    if guidance.isEmpty {
                        self.guidanceError = "No guidance found for this situation"
                    }
                    
                    print("✅ Loaded \(guidance.count) guidance entries")
                }
                
            } catch {
                print("❌ Error loading guidance: \(error)")
                await MainActor.run {
                    self.guidanceError = "Failed to load guidance. Please try again."
                    self.isLoadingGuidance = false
                }
            }
        }
    }
    
    // MARK: - Filter Management
    func updateDateFilter(_ filter: DateFilter) {
        selectedDateFilter = filter
        filterSituations()
    }
    
    func updateSort(_ sort: SortOption) {
        selectedSort = sort
        filterSituations()
    }
    
    func toggleSortDropdown() {
        isShowingSortDropdown.toggle()
    }
    
    func selectSortOption(_ option: SortOption) {
        selectedSort = option
        isShowingSortDropdown = false
        filterSituations()
    }
    
    func hideSortDropdown() {
        isShowingSortDropdown = false
    }
    
    func toggleCategory(_ category: CategoryFilter) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
        filterSituations()
    }
    
    func clearAllFilters() {
        selectedDateFilter = .allTime
        selectedSort = .mostRecent
        selectedCategories.removeAll()
        filterSituations()
    }
    
    // MARK: - Situation Actions (Step 4.6)
    
    func deleteSituation(id: String) {
        situationToDelete = id
        showingDeleteConfirmation = true
    }
    
    func confirmDelete() {
        guard let situationId = situationToDelete else { return }
        
        Task {
            do {
                await MainActor.run {
                    // Optimistically remove from UI
                    self.situations.removeAll { $0.id == situationId }
                    self.filterSituations()
                }
                
                // Delete from database
                try await ConversationService.shared.deleteSituation(situationId: situationId)
                print("✅ Situation deleted successfully")
                
            } catch {
                print("❌ Error deleting situation: \(error)")
                await MainActor.run {
                    // Reload situations to restore the failed delete
                    self.loadSituations()
                }
            }
        }
        
        // Clear the confirmation state
        situationToDelete = nil
        showingDeleteConfirmation = false
    }
    
    func cancelDelete() {
        situationToDelete = nil
        showingDeleteConfirmation = false
    }
    
    func toggleFavorite(id: String) {
        Task {
            do {
                // Optimistically update the UI immediately
                await MainActor.run {
                    if let index = self.situations.firstIndex(where: { $0.id == id }) {
                        let currentSituation = self.situations[index]
                        let newFavoriteStatus = !currentSituation.isFavorited
                        
                        // Create a copy with only the favorite status changed, preserving all dates
                        let updatedSituation = Situation(copying: currentSituation, isFavorited: newFavoriteStatus)
                        self.situations[index] = updatedSituation
                        self.filterSituations() // Update the grouped/filtered views
                    }
                }
                
                // Update in database (background operation)
                let newStatus = try await ConversationService.shared.toggleSituationFavorite(situationId: id)
                print("✅ Favorite status updated to: \(newStatus)")
                
            } catch {
                print("❌ Error toggling favorite: \(error)")
                await MainActor.run {
                    // Revert the optimistic update by reloading on error
                    self.loadSituations()
                }
            }
        }
    }
    
    deinit {
        searchDebounceTimer?.invalidate()
    }
}
