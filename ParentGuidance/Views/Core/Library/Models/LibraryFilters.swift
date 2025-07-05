//
//  LibraryFilters.swift
//  ParentGuidance
//
//  Created by alex kerss on 04/07/2025.
//

import Foundation
import SwiftUI

// MARK: - Date Filter
enum DateFilter: String, CaseIterable {
    case today = "today"
    case thisWeek = "thisWeek"
    case lastMonth = "lastMonth"
    case allTime = "allTime"
    
    var displayName: String {
        switch self {
        case .today:
            return "Today"
        case .thisWeek:
            return "This Week"
        case .lastMonth:
            return "Last Month"
        case .allTime:
            return "All Time"
        }
    }
    
    var sfSymbol: String {
        switch self {
        case .today:
            return "calendar.badge.clock"
        case .thisWeek:
            return "calendar"
        case .lastMonth:
            return "calendar.badge.minus"
        case .allTime:
            return "infinity"
        }
    }
    
    func filterSituations(_ situations: [Situation]) -> [Situation] {
        let calendar = Calendar.current
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        
        switch self {
        case .allTime:
            return situations
            
        case .today:
            return situations.filter { situation in
                guard let date = dateFormatter.date(from: situation.createdAt) else { return false }
                return calendar.isDateInToday(date)
            }
            
        case .thisWeek:
            return situations.filter { situation in
                guard let date = dateFormatter.date(from: situation.createdAt) else { return false }
                return calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true
            }
            
        case .lastMonth:
            return situations.filter { situation in
                guard let date = dateFormatter.date(from: situation.createdAt) else { return false }
                let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
                return date >= thirtyDaysAgo
            }
        }
    }
}

// MARK: - Sort Option
enum SortOption: String, CaseIterable {
    case mostRecent = "mostRecent"
    case oldest = "oldest"
    case alphabetical = "alphabetical"
    case mostRelevant = "mostRelevant"
    
    var displayName: String {
        switch self {
        case .mostRecent:
            return "Most Recent"
        case .oldest:
            return "Oldest First"
        case .alphabetical:
            return "A-Z"
        case .mostRelevant:
            return "Most Relevant"
        }
    }
    
    var sfSymbol: String {
        switch self {
        case .mostRecent:
            return "clock.arrow.circlepath"
        case .oldest:
            return "clock.badge.checkmark"
        case .alphabetical:
            return "textformat.abc"
        case .mostRelevant:
            return "star.fill"
        }
    }
    
    func sortSituations(_ situations: [Situation]) -> [Situation] {
        let dateFormatter = ISO8601DateFormatter()
        
        switch self {
        case .mostRecent:
            return situations.sorted { situation1, situation2 in
                guard let date1 = dateFormatter.date(from: situation1.createdAt),
                      let date2 = dateFormatter.date(from: situation2.createdAt) else {
                    return false
                }
                return date1 > date2
            }
            
        case .oldest:
            return situations.sorted { situation1, situation2 in
                guard let date1 = dateFormatter.date(from: situation1.createdAt),
                      let date2 = dateFormatter.date(from: situation2.createdAt) else {
                    return false
                }
                return date1 < date2
            }
            
        case .alphabetical:
            return situations.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            
        case .mostRelevant:
            return situations.sorted { situation1, situation2 in
                guard let date1 = dateFormatter.date(from: situation1.updatedAt),
                      let date2 = dateFormatter.date(from: situation2.updatedAt) else {
                    return false
                }
                return date1 > date2
            }
        }
    }
}

// MARK: - Category Filter
enum CategoryFilter: String, CaseIterable {
    case sleep = "sleep"
    case food = "food"
    case behavior = "behavior"
    case school = "school"
    case play = "play"
    case health = "health"
    case social = "social"
    case emotions = "emotions"
    case chores = "chores"
    case transportation = "transportation"
    
    var displayName: String {
        switch self {
        case .sleep:
            return "Sleep"
        case .food:
            return "Food"
        case .behavior:
            return "Behavior"
        case .school:
            return "School"
        case .play:
            return "Play"
        case .health:
            return "Health"
        case .social:
            return "Social"
        case .emotions:
            return "Emotions"
        case .chores:
            return "Chores"
        case .transportation:
            return "Transportation"
        }
    }
    
    var sfSymbol: String {
        switch self {
        case .sleep:
            return "moon.fill"
        case .food:
            return "fork.knife"
        case .behavior:
            return "person.fill.questionmark"
        case .school:
            return "book.fill"
        case .play:
            return "gamecontroller.fill"
        case .health:
            return "cross.case.fill"
        case .social:
            return "person.2.fill"
        case .emotions:
            return "heart.fill"
        case .chores:
            return "trash.fill"
        case .transportation:
            return "car.fill"
        }
    }
    
    var keywords: [String] {
        switch self {
        case .sleep:
            return ["sleep", "bedtime", "nap", "tired", "nightmare", "bed", "pillow"]
        case .food:
            return ["food", "eat", "dinner", "lunch", "breakfast", "snack", "hungry", "meal"]
        case .behavior:
            return ["behavior", "tantrum", "meltdown", "discipline", "rules", "consequences"]
        case .school:
            return ["school", "homework", "teacher", "class", "study", "learning", "education"]
        case .play:
            return ["play", "toy", "game", "fun", "activity", "entertainment", "playground"]
        case .health:
            return ["health", "sick", "medicine", "doctor", "teeth", "brush", "bath", "hygiene"]
        case .social:
            return ["friend", "social", "sharing", "cooperation", "kindness", "manners"]
        case .emotions:
            return ["angry", "sad", "happy", "scared", "frustrated", "excited", "calm", "upset"]
        case .chores:
            return ["chore", "clean", "tidy", "help", "responsible", "organize", "duties"]
        case .transportation:
            return ["car", "drive", "pickup", "bus", "walk", "bike", "travel", "transport"]
        }
    }
    
    func matchesSituation(_ situation: Situation) -> Bool {
        let text = "\(situation.title) \(situation.description)".lowercased()
        return keywords.contains { keyword in
            text.contains(keyword)
        }
    }
}
