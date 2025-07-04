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
                        
                        RoutineCard(
                            time: formatTime(from: situation.createdAt),
                            activity: situation.title,
                            icon: getTimePeriodIcon(for: timePeriod)
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
}

#Preview {
    TodayTimelineView(situations: [])
}
