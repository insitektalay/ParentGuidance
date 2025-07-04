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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Search bar
                SearchBar()
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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Situations")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(ColorPalette.white.opacity(0.9))
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 12) {
                            ForEach(controller.situations, id: \.id) { situation in
                                SituationCard(
                                    emoji: getEmojiForSituation(situation),
                                    title: situation.title,
                                    date: formatDate(situation.createdAt),
                                    onTap: {
                                        print("Situation tapped: \(situation.title)")
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 100) // Space for tab bar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
    }
    
    private func getEmojiForSituation(_ situation: Situation) -> String {
        // Simple emoji mapping based on keywords in title/description
        let text = "\(situation.title) \(situation.description)".lowercased()
        
        if text.contains("teeth") || text.contains("brush") {
            return "🦷"
        } else if text.contains("bath") || text.contains("bedtime") || text.contains("sleep") {
            return "🛁"
        } else if text.contains("car") || text.contains("drive") || text.contains("pickup") {
            return "🚗"
        } else if text.contains("dinner") || text.contains("food") || text.contains("eat") {
            return "🍽️"
        } else if text.contains("school") || text.contains("homework") {
            return "📚"
        } else if text.contains("play") || text.contains("toy") {
            return "🎮"
        } else if text.contains("tantrum") || text.contains("meltdown") {
            return "😭"
        } else {
            return "💬"
        }
    }
    
    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return "Recent"
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return displayFormatter.string(from: date)
        }
    }
}

#Preview {
    LibraryView()
}
