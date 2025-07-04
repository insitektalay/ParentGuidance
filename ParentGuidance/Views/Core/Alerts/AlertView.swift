//
//  AlertView.swift
//  ParentGuidance
//
//  Created by alex kerss on 29/06/2025.
//

import SwiftUI

struct AlertView: View {
    @State private var selectedCategory: AlertCategory = .recent
    
    enum AlertCategory: String, CaseIterable {
        case recent = "Recent Alerts"
        case previous = "Previous Alerts"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category selector
            HStack(spacing: 0) {
                ForEach(AlertCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category.rawValue)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedCategory == category ? ColorPalette.terracotta : ColorPalette.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Rectangle()
                                    .fill(selectedCategory == category ? ColorPalette.white.opacity(0.1) : Color.clear)
                            )
                            .overlay(
                                Rectangle()
                                    .fill(selectedCategory == category ? ColorPalette.terracotta : Color.clear)
                                    .frame(height: 2)
                                    .offset(y: 16),
                                alignment: .bottom
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Content area
            ScrollView {
                LazyVStack(spacing: 0) {
                    switch selectedCategory {
                    case .recent:
                        recentAlertsContent
                    case .previous:
                        previousAlertsContent
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 100) // Space for tab bar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
    }
    
    private var recentAlertsContent: some View {
        VStack(spacing: 0) {
            NotificationCard(
                content: "Based on the situations you've shared, some parents find the Zones of Regulation framework helpful for understanding intense emotional reactions and helping kids return to a calm state.",
                onYesTryThis: { print("Yes, Try This tapped") },
                onNotRightNow: { print("Not Right Now tapped") },
                onMaybeLater: { print("Maybe Later tapped") },
                onLearnMore: { print("Learn More tapped") }
            )
            
            NotificationCard(
                content: "We've noticed that Alex seems to benefit from advance warning before transitions. This pattern is common and there are strategies that can help make these moments smoother.",
                onYesTryThis: { print("Yes, Try This tapped") },
                onNotRightNow: { print("Not Right Now tapped") },
                onMaybeLater: { print("Maybe Later tapped") },
                onLearnMore: { print("Learn More tapped") }
            )
        }
    }
    
    private var previousAlertsContent: some View {
        VStack(spacing: 0) {
            NotificationCard(
                content: "Many families find that establishing a consistent bedtime routine helps children feel more secure and reduces resistance to sleep-related activities like teeth brushing.",
                onYesTryThis: { print("Yes, Try This tapped") },
                onNotRightNow: { print("Not Right Now tapped") },
                onMaybeLater: { print("Maybe Later tapped") },
                onLearnMore: { print("Learn More tapped") }
            )
            
            NotificationCard(
                content: "Visual schedules and timers can be particularly effective for children who need extra support with time awareness and transitions between activities.",
                onYesTryThis: { print("Yes, Try This tapped") },
                onNotRightNow: { print("Not Right Now tapped") },
                onMaybeLater: { print("Maybe Later tapped") },
                onLearnMore: { print("Learn More tapped") }
            )
        }
    }
}

#Preview {
    AlertView()
}
