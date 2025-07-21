//
//  SettingsFrameworkState.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

// MARK: - Framework State Management

class SettingsFrameworkState: ObservableObject {
    @Published var frameworks: [FrameworkRecommendation] = []
    @Published var activeFrameworkIds: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingRemovalConfirmation: Bool = false
    @Published var frameworkToRemove: FrameworkRecommendation?
    @Published var isRemoving: Bool = false
    
    private var familyId: String?
    
    @MainActor
    func loadFrameworks(familyId: String?) async {
        guard let familyId = familyId else {
            print("❌ No family ID available for SettingsFrameworkState")
            return
        }
        
        self.familyId = familyId
        isLoading = true
        errorMessage = nil
        
        do {
            // Load all frameworks for this family
            frameworks = try await FrameworkStorageService.shared.getFrameworkHistory(familyId: familyId)
            
            // Load active framework to identify which ones are active
            if let activeFramework = try await FrameworkStorageService.shared.getActiveFramework(familyId: familyId) {
                activeFrameworkIds = [activeFramework.id]
                print("✅ Settings: Loaded \(frameworks.count) frameworks, 1 active: \(activeFramework.frameworkName)")
            } else {
                activeFrameworkIds = []
                print("✅ Settings: Loaded \(frameworks.count) frameworks, none active")
            }
        } catch {
            print("❌ Settings: Failed to load frameworks: \(error)")
            errorMessage = "Unable to load frameworks"
        }
        
        isLoading = false
    }
    
    @MainActor
    func toggleFramework(frameworkId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if activeFrameworkIds.contains(frameworkId) {
                // Deactivate framework
                try await FrameworkStorageService.shared.deactivateFramework(id: frameworkId)
                activeFrameworkIds.remove(frameworkId)
                print("✅ Settings: Framework deactivated: \(frameworkId)")
            } else {
                // Activate framework
                try await FrameworkStorageService.shared.activateFramework(id: frameworkId)
                activeFrameworkIds.insert(frameworkId)
                print("✅ Settings: Framework activated: \(frameworkId)")
            }
        } catch {
            print("❌ Settings: Failed to toggle framework: \(error)")
            errorMessage = "Unable to update framework"
        }
        
        isLoading = false
    }
    
    @MainActor
    func removeFramework(frameworkId: String) async {
        isRemoving = true
        errorMessage = nil
        
        do {
            // Remove from database
            try await FrameworkStorageService.shared.deleteFrameworkRecommendation(id: frameworkId)
            
            // Remove from local state
            frameworks.removeAll { $0.id == frameworkId }
            activeFrameworkIds.remove(frameworkId)
            
            print("✅ Settings: Framework removed successfully: \(frameworkId)")
            
            // Clear removal state
            frameworkToRemove = nil
            showingRemovalConfirmation = false
            
        } catch {
            print("❌ Settings: Failed to remove framework: \(error)")
            errorMessage = "Unable to remove framework"
        }
        
        isRemoving = false
    }
    
    @MainActor
    func prepareForRemoval(framework: FrameworkRecommendation) {
        frameworkToRemove = framework
        showingRemovalConfirmation = true
    }
    
    @MainActor
    func cancelRemoval() {
        frameworkToRemove = nil
        showingRemovalConfirmation = false
    }
}
