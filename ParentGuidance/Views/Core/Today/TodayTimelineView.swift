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
                        RoutineCard(
                            time: formatTime(from: situation.createdAt),
                            activity: situation.title,
                            icon: "lightbulb"
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100) // Extra padding for tab bar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
    }
    
    private func formatTime(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "Unknown" }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return timeFormatter.string(from: date)
    }
}

#Preview {
    TodayTimelineView(situations: [])
}
