//
//  LibrarySelectionManager.swift
//  ParentGuidance
//
//  Created by alex kerss on 07/07/2025.
//

import Foundation
import SwiftUI

class LibrarySelectionManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Whether the library is currently in selection mode
    @Published var isInSelectionMode: Bool = false
    
    /// Set of selected situation IDs
    @Published var selectedSituationIds: Set<String> = []
    
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
    
    /// Initiate framework generation process
    /// This is a placeholder method that will be implemented in Step 5
    func generateFramework() async {
        guard canGenerateFramework else {
            print("❌ Cannot generate framework: insufficient selections (\(selectedCount) < 2)")
            return
        }
        
        print("🚀 Framework generation initiated with \(selectedCount) situations")
        print("🔧 TODO: Implement framework generation in Step 5")
        
        // TODO: Step 5 - Implement actual framework generation
        // 1. Extract situation data using FrameworkGenerationService
        // 2. Call OpenAI API with prompt ID
        // 3. Parse response and create FrameworkRecommendation
        // 4. Navigate to Alerts page to show recommendation
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