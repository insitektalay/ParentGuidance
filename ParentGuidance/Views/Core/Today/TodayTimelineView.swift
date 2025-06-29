//
//  TodayTimelineView.swift
//  ParentGuidance
//
//  Created by alex kerss on 29/06/2025.
//

import SwiftUI

struct TodayTimelineView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Morning routines
                RoutineCard(time: "6:30 AM", activity: "Wake Up Routine", icon: "sun.max")
                RoutineCard(time: "7:00 AM", activity: "Get Dressed", icon: "tshirt")
                RoutineCard(time: "7:55 AM", activity: "Morning Teeth Brushing")
                RoutineCard(time: "8:05 AM", activity: "Drive to School", icon: "car")
                RoutineCard(time: "8:30 AM", activity: "School Drop-off", icon: "building.2")
                
                // Midday
                RoutineCard(time: "12:00 PM", activity: "Lunch Break", icon: "fork.knife")
                
                // Afternoon
                RoutineCard(time: "3:30 PM", activity: "School Pickup", icon: "car")
                RoutineCard(time: "4:00 PM", activity: "Snack Time", icon: "leaf")
                RoutineCard(time: "4:30 PM", activity: "Homework Time", icon: "book.closed")
                RoutineCard(time: "5:30 PM", activity: "Play Time", icon: "gamecontroller")
                
                // Evening
                RoutineCard(time: "6:00 PM", activity: "Dinner Time", icon: "fork.knife")
                RoutineCard(time: "7:00 PM", activity: "Family Time", icon: "person.3")
                RoutineCard(time: "7:30 PM", activity: "Bedtime Routine", icon: "moon")
                RoutineCard(time: "8:00 PM", activity: "Story Time", icon: "book")
                RoutineCard(time: "8:30 PM", activity: "Lights Out", icon: "moon.zzz")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100) // Extra padding for tab bar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
    }
}

#Preview {
    TodayTimelineView()
}
