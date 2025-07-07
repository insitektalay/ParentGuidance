//
//  LibrarySelectionManager.swift
//  ParentGuidance
//
//  Created by alex kerss on 07/07/2025.
//

import Foundation
import SwiftUI
import Supabase

class LibrarySelectionManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Whether the library is currently in selection mode
    @Published var isInSelectionMode: Bool = false
    
    /// Set of selected situation IDs
    @Published var selectedSituationIds: Set<String> = []
    
    /// Whether framework generation is currently in progress
    @Published var isGeneratingFramework: Bool = false
    
    // MARK: - Computed Properties
    
    /// Number of currently selected situations
    var selectedCount: Int {
        selectedSituationIds.count
    }
    
    /// Whether any situations are currently selected
    var hasSelections: Bool {
        !selectedSituationIds.isEmpty
    }
    
    /// Whether enough situations are selected to generate a framework
    var canGenerateFramework: Bool {
        selectedSituationIds.count >= 2 // Minimum 2 situations for meaningful framework
    }
    
    // MARK: - Selection Management Methods
    
    /// Enter selection mode and clear any previous selections
    func enterSelectionMode() {
        print("📋 Entering selection mode")
        isInSelectionMode = true
        selectedSituationIds.removeAll()
    }
    
    /// Exit selection mode and clear all selections
    func exitSelectionMode() {
        print("❌ Exiting selection mode")
        isInSelectionMode = false
        selectedSituationIds.removeAll()
    }
    
    /// Toggle selection state for a specific situation
    /// - Parameter situationId: The ID of the situation to toggle
    func toggleSelection(situationId: String) {
        if selectedSituationIds.contains(situationId) {
            selectedSituationIds.remove(situationId)
            print("➖ Deselected situation: \(situationId)")
        } else {
            selectedSituationIds.insert(situationId)
            print("➕ Selected situation: \(situationId)")
        }
        print("📊 Total selected: \(selectedCount)")
    }
    
    /// Check if a specific situation is currently selected
    /// - Parameter situationId: The ID of the situation to check
    /// - Returns: True if the situation is selected
    func isSelected(situationId: String) -> Bool {
        selectedSituationIds.contains(situationId)
    }
    
    /// Select all provided situations
    /// - Parameter situationIds: Array of situation IDs to select
    func selectAll(situationIds: [String]) {
        print("✅ Selecting all \(situationIds.count) situations")
        selectedSituationIds = Set(situationIds)
    }
    
    /// Clear all selections without exiting selection mode
    func clearSelections() {
        print("🗑️ Clearing all selections")
        selectedSituationIds.removeAll()
    }
    
    /// Filter an array of situations to only include selected ones
    /// - Parameter situations: Array of all situations
    /// - Returns: Array containing only selected situations
    func getSelectedSituations(from situations: [Situation]) -> [Situation] {
        return situations.filter { selectedSituationIds.contains($0.id) }
    }
    
    // MARK: - Framework Generation Methods (Placeholder for Step 5)
    
    /// Initiate framework generation process using FrameworkGenerationService
    func generateFramework() async {
        guard canGenerateFramework else {
            print("❌ Cannot generate framework: insufficient selections (\(selectedCount) < 2)")
            return
        }
        
        // Set loading state
        await MainActor.run {
            isGeneratingFramework = true
        }
        
        print("🚀 Framework generation initiated with \(selectedCount) situations")
        
        do {
            // Step 1: Get user's API key
            let userId = "15359b56-cabf-4b6a-9d2a-a3b11001b8e2" // TODO: Get from current user context
            let apiKey = try await getUserApiKey(userId: userId)
            
            // Step 2: Get situations from selection
            let situationIds = Array(selectedSituationIds)
            let familyId = "5627b7a3-3ba8-4f1b-92a8-ba0e460863e5" // TODO: Get from user context
            
            // Step 3: Generate framework using FrameworkGenerationService
            let frameworkRecommendation = try await FrameworkGenerationService.shared.generateFramework(
                from: situationIds,
                familyId: familyId,
                apiKey: apiKey
            )
            
            print("✅ Framework generation completed: \(frameworkRecommendation.frameworkName)")
            
            // Step 6: Save framework recommendation to database
            print("💾 Saving framework recommendation to database...")
            let savedFrameworkId = try await FrameworkStorageService.shared.saveFrameworkRecommendation(
                frameworkRecommendation,
                familyId: familyId,
                situationIds: situationIds
            )
            print("✅ Framework recommendation saved with ID: \(savedFrameworkId)")
            
            // Step 8: Navigate to Alerts page to show recommendation
            await MainActor.run {
                print("📱 Triggering navigation to Alerts tab...")
                TabNavigationManager.shared.navigateToTab(.alerts)
                // Clear loading state after successful generation and navigation
                isGeneratingFramework = false
            }
            
        } catch {
            print("❌ Framework generation/storage failed: \(error)")
            
            if let frameworkError = error as? FrameworkGenerationError {
                print("   Generation error: \(frameworkError.localizedDescription)")
            } else if let storageError = error as? FrameworkStorageError {
                print("   Storage error: \(storageError.localizedDescription)")
            }
            
            // Clear loading state on error
            await MainActor.run {
                isGeneratingFramework = false
            }
            
            // TODO: Step 7 - Show error message in UI
        }
    }
    
    /// Get user's API key (helper method)
    private func getUserApiKey(userId: String) async throws -> String {
        let supabase = SupabaseManager.shared.client
        
        // Query just the API key field and decode as a dictionary
        let response: [[String: String?]] = try await supabase
            .from("profiles")
            .select("user_api_key")
            .eq("id", value: userId)
            .execute()
            .value
        
        guard let row = response.first,
              let apiKey = row["user_api_key"] as? String,
              !apiKey.isEmpty else {
            throw FrameworkGenerationError.invalidAPIKey
        }
        
        return apiKey
    }
    
    /// Validate that framework generation requirements are met
    /// - Returns: True if framework can be generated, false otherwise
    func validateFrameworkGeneration() -> (canGenerate: Bool, errorMessage: String?) {
        if selectedSituationIds.isEmpty {
            return (false, "Please select at least 2 situations to generate a framework")
        }
        
        if selectedSituationIds.count < 2 {
            return (false, "Please select at least 2 situations for a meaningful framework recommendation")
        }
        
        if selectedSituationIds.count > 10 {
            return (false, "Please select no more than 10 situations to keep the analysis focused")
        }
        
        return (true, nil)
    }
    
    // MARK: - Utility Methods
    
    /// Get a summary of current selection state for debugging
    var selectionSummary: String {
        if !isInSelectionMode {
            return "Not in selection mode"
        }
        
        if selectedSituationIds.isEmpty {
            return "Selection mode active, no situations selected"
        }
        
        return "Selection mode active, \(selectedCount) situation(s) selected"
    }
    
    /// Reset the selection manager to initial state
    func reset() {
        print("🔄 Resetting LibrarySelectionManager")
        isInSelectionMode = false
        selectedSituationIds.removeAll()
    }
}

// MARK: - Extensions

extension LibrarySelectionManager {
    /// Convenience method to handle "Generate Framework" button tap
    func handleGenerateFrameworkTap() {
        let validation = validateFrameworkGeneration()
        
        if validation.canGenerate {
            Task {
                await generateFramework()
            }
        } else {
            print("⚠️ Framework generation validation failed: \(validation.errorMessage ?? "Unknown error")")
            // TODO: Step 7 - Show error message in UI
        }
    }
    
    /// Convenience method to get display text for selection count
    var selectionCountText: String {
        if selectedCount == 0 {
            return "No situations selected"
        } else if selectedCount == 1 {
            return "1 situation selected"
        } else {
            return "\(selectedCount) situations selected"
        }
    }
}