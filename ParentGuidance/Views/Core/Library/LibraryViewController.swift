//
//  LibraryViewController.swift
//  ParentGuidance
//
//  Created by alex kerss on 04/07/2025.
//

import Foundation
import SwiftUI

class LibraryViewController: ObservableObject {
    @Published var viewState: ViewState = .loading
    @Published var situations: [Situation] = []
    @Published var errorMessage: String = ""
    
    enum ViewState {
        case loading
        case error
        case empty
        case content
    }
    
    init() {
        loadSituations()
    }
    
    func loadSituations() {
        viewState = .loading
        
        Task {
            do {
                let userId = "15359b56-cabf-4b6a-9d2a-a3b11001b8e2"
                let userProfile = try await SimpleOnboardingManager.shared.loadUserProfile(userId: userId)
                
                guard let familyId = userProfile.familyId else {
                    print("❌ No family_id found for user")
                    await MainActor.run {
                        self.viewState = .empty
                    }
                    return
                }
                
                print("📚 Loading all situations for family: \(familyId)")
                let allSituations = try await ConversationService.shared.getAllSituations(familyId: familyId)
                
                await MainActor.run {
                    self.situations = allSituations
                    self.viewState = allSituations.isEmpty ? .empty : .content
                }
                
            } catch {
                print("❌ Error loading situations: \(error)")
                await MainActor.run {
                    self.errorMessage = "Failed to load situations. Please try again."
                    self.viewState = .error
                }
            }
        }
    }
    
    func retry() {
        loadSituations()
    }
    
    func refreshSituations() {
        loadSituations()
    }
}
