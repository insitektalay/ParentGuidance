//
//  TodayTimelineView.swift
//  ParentGuidance
//
//  Created by alex kerss on 29/06/2025.
//

import SwiftUI
import Foundation

struct TodayTimelineView: View {
    let situations: [Situation]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if situations.isEmpty {
                    // Empty state message
                    Text("No situations recorded today")
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                        .padding(.top, 32)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(situations, id: \.id) { situation in
                        let timePeriod = getTimePeriod(from: situation.createdAt)
                        let dynamicIcon = getSituationSpecificIcon(for: situation)
                        
                        RoutineCard(
                            situation: situation,
                            time: formatTime(from: situation.createdAt),
                            icon: dynamicIcon
                        )
                        .opacity(getTimePeriodOpacity(for: timePeriod))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100) // Extra padding for tab bar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
    }
    
    private func getTimePeriod(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "unknown" }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        switch hour {
        case 5..<12:
            return "morning"
        case 12..<17:
            return "afternoon"
        case 17..<21:
            return "evening"
        default:
            return "night"
        }
    }
    
    private func getTimePeriodIcon(for period: String) -> String {
        switch period {
        case "morning":
            return "sun.max"
        case "afternoon":
            return "sun.max.fill"
        case "evening":
            return "sun.min"
        case "night":
            return "moon"
        default:
            return "lightbulb"
        }
    }
    
    private func getTimePeriodOpacity(for period: String) -> Double {
        // Subtle visual distinction - more recent time periods slightly more prominent
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        
        let currentPeriod: String
        switch currentHour {
        case 5..<12:
            currentPeriod = "morning"
        case 12..<17:
            currentPeriod = "afternoon"
        case 17..<21:
            currentPeriod = "evening"
        default:
            currentPeriod = "night"
        }
        
        // Current time period gets full opacity, others slightly dimmed
        return period == currentPeriod ? 1.0 : 0.85
    }
    
    private func formatTime(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "Unknown" }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        // Handle future dates (shouldn't happen, but just in case)
        if timeInterval < 0 {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            timeFormatter.timeZone = TimeZone.current
            return timeFormatter.string(from: date)
        }
        
        let minutes = Int(timeInterval / 60)
        let hours = Int(timeInterval / 3600)
        
        switch timeInterval {
        case 0..<60:
            return "Just now"
        case 60..<3600:
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        case 3600..<21600: // Less than 6 hours
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        default:
            // For older situations, show actual time
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            timeFormatter.timeZone = TimeZone.current
            return timeFormatter.string(from: date)
        }
    }
    
    // MARK: - Dynamic Icon Selection System
    
    private func getSituationSpecificIcon(for situation: Situation) -> String {
        let text = "\(situation.title) \(situation.description)".lowercased()
        
        // Extract keywords and find best matching icon
        let bestMatch = findBestIconMatch(in: text)
        
        // Fallback hierarchy: specific icon -> time-period icon -> default
        if let specificIcon = bestMatch {
            return specificIcon
        } else {
            // Fall back to time-period icon from Baby Step 3
            let timePeriod = getTimePeriod(from: situation.createdAt)
            return getTimePeriodIcon(for: timePeriod)
        }
    }
    
    private func findBestIconMatch(in text: String) -> String? {
        // Create comprehensive keyword → SF Symbol mapping
        let iconMappings: [String: String] = [
            // Daily Care & Hygiene
            "teeth": "toothbrush.fill",
            "brush": "toothbrush.fill",
            "brushing": "toothbrush.fill",
            "dental": "toothbrush.fill",
            "bath": "bathtub.fill",
            "shower": "shower.fill",
            "washing": "hands.sparkles.fill",
            "wash": "hands.sparkles.fill",
            "soap": "hands.sparkles.fill",
            "clean": "sparkles",
            
            // Sleep & Rest
            "sleep": "bed.double.fill",
            "bed": "bed.double.fill",
            "bedtime": "bed.double.fill",
            "nap": "bed.double.fill",
            "tired": "moon.zzz.fill",
            "sleepy": "moon.zzz.fill",
            
            // Food & Eating
            "eat": "fork.knife",
            "eating": "fork.knife",
            "food": "fork.knife",
            "meal": "fork.knife",
            "dinner": "fork.knife",
            "lunch": "fork.knife",
            "breakfast": "fork.knife",
            "snack": "carrot.fill",
            "hungry": "fork.knife",
            "kitchen": "fork.knife",
            "cooking": "frying.pan.fill",
            
            // Transportation
            "car": "car.fill",
            "drive": "car.fill",
            "driving": "car.fill",
            "bus": "bus.fill",
            "walk": "figure.walk",
            "walking": "figure.walk",
            "bike": "bicycle",
            "scooter": "scooter",
            
            // School & Learning
            "school": "building.2.fill",
            "homework": "pencil.and.outline",
            "study": "book.fill",
            "reading": "book.fill",
            "book": "book.fill",
            "learn": "graduationcap.fill",
            "teacher": "person.chalkboard",
            "class": "building.2.fill",
            
            // Play & Activities
            "play": "gamecontroller.fill",
            "playing": "gamecontroller.fill",
            "toy": "teddybear.fill",
            "toys": "teddybear.fill",
            "game": "gamecontroller.fill",
            "lego": "building.2.crop.circle.fill",
            "blocks": "building.2.crop.circle.fill",
            "puzzle": "puzzlepiece.fill",
            
            // Sports & Exercise
            "soccer": "soccerball",
            "football": "football.fill",
            "basketball": "basketball.fill",
            "tennis": "tennis.racket",
            "swimming": "figure.pool.swim",
            "run": "figure.run",
            "running": "figure.run",
            "exercise": "figure.strengthtraining.traditional",
            "playground": "figure.playground",
            
            // Technology & Media
            "tv": "tv.fill",
            "television": "tv.fill",
            "screen": "tv.fill",
            "ipad": "ipad",
            "tablet": "ipad",
            "phone": "iphone",
            "video": "play.rectangle.fill",
            "movie": "tv.fill",
            
            // Social & Relationships
            "friend": "person.2.fill",
            "friends": "person.2.fill",
            "sibling": "person.2.fill",
            "brother": "person.2.fill",
            "sister": "person.2.fill",
            "share": "arrow.triangle.2.circlepath",
            "sharing": "arrow.triangle.2.circlepath",
            "fight": "exclamationmark.triangle.fill",
            "argue": "exclamationmark.triangle.fill",
            
            // Emotions & Behavior
            "tantrum": "exclamationmark.triangle.fill",
            "angry": "flame.fill",
            "mad": "flame.fill",
            "upset": "cloud.rain.fill",
            "cry": "drop.fill",
            "crying": "drop.fill",
            "sad": "cloud.fill",
            "happy": "sun.max.fill",
            "excited": "star.fill",
            "scared": "exclamationmark.triangle.fill",
            "afraid": "exclamationmark.triangle.fill",
            
            // Health & Medical
            "sick": "cross.case.fill",
            "medicine": "pills.fill",
            "doctor": "stethoscope",
            "fever": "thermometer",
            "hurt": "bandage.fill",
            "pain": "bandage.fill",
            
            // Locations & Places
            "home": "house.fill",
            "store": "cart.fill",
            "shopping": "cart.fill",
            "park": "tree.fill",
            "restaurant": "fork.knife.circle.fill",
            "library": "building.columns.fill",
            "church": "building.columns.fill",
            "hospital": "cross.case.fill",
            
            // Transitions & Changes
            "leave": "arrow.right.circle.fill",
            "leaving": "arrow.right.circle.fill",
            "go": "arrow.right.circle.fill",
            "going": "arrow.right.circle.fill",
            "transition": "arrow.triangle.turn.up.right.circle.fill",
            "change": "arrow.triangle.turn.up.right.circle.fill",
            "stop": "stop.circle.fill",
            "start": "play.circle.fill",
            
            // Time-specific contexts
            "morning": "sun.max.fill",
            "afternoon": "sun.max.fill",
            "evening": "sun.min.fill",
            "night": "moon.fill"
        ]
        
        // Find the best matching icon by checking for keywords in text
        var bestMatch: String?
        var longestMatch = 0
        
        for (keyword, icon) in iconMappings {
            if text.contains(keyword) && keyword.count > longestMatch {
                bestMatch = icon
                longestMatch = keyword.count
            }
        }
        
        return bestMatch
    }
}

#Preview {
    TodayTimelineView(situations: [])
}
