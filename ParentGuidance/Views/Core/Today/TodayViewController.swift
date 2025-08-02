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
    @Environment(\.colorScheme) private var colorScheme
    @State private var isLoading = true
    @State private var situations: [Situation] = []
    @State private var errorMessage: String?
    @EnvironmentObject var appCoordinator: AppCoordinator
    let onNavigateToNewTab: () -> Void
    
    var body: some View {
        Group {
            if isLoading {
                // Show loading state
                VStack {
                    ProgressView()
                        .tint(SemanticColors.accent)
                    Text(String(localized: "today.loading"))
                        .font(.system(size: 16))
                        .foregroundColor(SemanticColors.secondaryText)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SemanticColors.primaryBackground)
            } else if let error = errorMessage {
                // Show error state (fallback to timeline)
                VStack {
                    Text(String(localized: "today.error.title"))
                        .font(.system(size: 18))
                        .foregroundColor(SemanticColors.primaryText)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.tertiaryText)
                        .padding(.top, 4)
                    
                    // Still show timeline as fallback
                    TodayTimelineView(situations: situations)
                        .padding(.top, 16)
                }
                .background(SemanticColors.primaryBackground)
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
            guard let userId = appCoordinator.currentUserId else {
                print("❌ No current user ID available")
                await MainActor.run {
                    self.situations = []
                    self.isLoading = false
                }
                return
            }
            let userProfile = try await AuthService.shared.loadUserProfile(userId: userId)
            
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
