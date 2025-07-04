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
    @Published var searchQuery: String = "" {
        didSet {
            filterSituations()
        }
    }
    @Published var errorMessage: String = ""
    
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
                let userProfile = try await SimpleOnboardingManager.shared.loadUserProfile(userId: userId)
                
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
                    self.filteredSituations = allSituations
                    self.viewState = allSituations.isEmpty ? .empty : .content
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
    
    private func filterSituations() {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedQuery.isEmpty {
            filteredSituations = situations
        } else {
            filteredSituations = situations.filter { situation in
                situation.title.lowercased().contains(trimmedQuery.lowercased()) ||
                situation.description.lowercased().contains(trimmedQuery.lowercased())
            }
        }
    }
    
    // MARK: - Date Grouping Foundation
    struct SituationGroup {
        let title: String
        let situations: [Situation]
    }
    
    var groupedSituations: [SituationGroup] {
        let calendar = Calendar.current
        let now = Date()
        
        var todayGroup: [Situation] = []
        var yesterdayGroup: [Situation] = []
        var thisWeekGroup: [Situation] = []
        var olderGroup: [Situation] = []
        
        for situation in filteredSituations {
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
        
        return groups
    }
}
