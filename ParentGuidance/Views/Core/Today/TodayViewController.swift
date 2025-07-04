//
//  TodayViewController.swift
//  ParentGuidance
//
//  Created by alex kerss on 03/07/2025.
//

import SwiftUI
import Foundation
import Supabase

struct TodayViewController: View {
    @State private var isLoading = true
    @State private var situations: [Situation] = []
    @State private var errorMessage: String?
    let onNavigateToNewTab: () -> Void
    
    var body: some View {
        Group {
            if isLoading {
                // Show loading state
                VStack {
                    ProgressView()
                        .tint(ColorPalette.terracotta)
                    Text("Loading today's timeline...")
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ColorPalette.navy)
            } else if let error = errorMessage {
                // Show error state (fallback to timeline)
                VStack {
                    Text("Unable to load timeline")
                        .font(.system(size: 18))
                        .foregroundColor(ColorPalette.white)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                        .padding(.top, 4)
                    
                    // Still show timeline as fallback
                    TodayTimelineView(situations: situations)
                        .padding(.top, 16)
                }
                .background(ColorPalette.navy)
            } else if !situations.isEmpty {
                // Show timeline with data
                TodayTimelineView(situations: situations)
            } else {
                // Show empty state
                TodayEmptyView(
                    onCreateFirstSituation: onNavigateToNewTab
                )
            }
        }
        .task {
            await loadTodaysSituations()
        }
    }
    
    private func loadTodaysSituations() async {
        print("🔄 TodayViewController: Loading today's situations...")
        
        do {
            // Get current user and family ID
            let userId = "15359b56-cabf-4b6a-9d2a-a3b11001b8e2" // TODO: Get from auth
            let userProfile = try await SimpleOnboardingManager.shared.loadUserProfile(userId: userId)
            
            guard let familyId = userProfile.familyId else {
                print("❌ No family ID found for user")
                await MainActor.run {
                    self.situations = []
                    self.isLoading = false
                }
                return
            }
            
            // Get today's situations
            let todaysSituations = try await ConversationService.shared.getTodaysSituations(familyId: familyId)
            
            await MainActor.run {
                self.situations = todaysSituations
                self.isLoading = false
                print("✅ TodayViewController: Loaded \(todaysSituations.count) situations for today")
            }
            
        } catch {
            print("❌ TodayViewController: Error loading situations: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.situations = [] // Fallback to show empty state on error
                self.isLoading = false
            }
        }
    }
}
