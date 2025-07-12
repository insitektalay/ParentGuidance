//
//  AlertView.swift
//  ParentGuidance
//
//  Created by alex kerss on 29/06/2025.
//

import SwiftUI

struct AlertView: View {
    @State private var selectedCategory: AlertCategory = .recent
    @EnvironmentObject var appCoordinator: AppCoordinator
    
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
            // Framework recommendations (highest priority)
            FrameworkAlertContainer(familyId: nil) // TODO: Get familyId from user profile
        }
    }
    
    private var previousAlertsContent: some View {
        VStack(spacing: 0) {
            // Previous alerts content - empty for now
            // Future: Show dismissed or historical framework recommendations
        }
    }
}

#Preview {
    AlertView()
}
