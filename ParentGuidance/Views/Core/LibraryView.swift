//
//  LibraryView.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/06/2025.
//

import SwiftUI

struct LibraryView: View {
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
                
                // Recent Situations section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Situations")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 12) {
                        SituationCard(
                            emoji: "🦷",
                            title: "Morning teeth brushing",
                            date: "Oct 15",
                            onTap: {
                                print("Morning teeth brushing tapped")
                            }
                        )
                        
                        SituationCard(
                            emoji: "🛁",
                            title: "Bedtime meltdown",
                            date: "Oct 14",
                            onTap: {
                                print("Bedtime meltdown tapped")
                            }
                        )
                        
                        SituationCard(
                            emoji: "🚗",
                            title: "School pickup",
                            date: "Oct 12",
                            onTap: {
                                print("School pickup tapped")
                            }
                        )
                        
                        SituationCard(
                            emoji: "🍽️",
                            title: "Dinner time",
                            date: "Oct 11",
                            onTap: {
                                print("Dinner time tapped")
                            }
                        )
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 100) // Space for tab bar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
    }
}

#Preview {
    LibraryView()
}
