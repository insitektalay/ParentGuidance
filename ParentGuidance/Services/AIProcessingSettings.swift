//
//  AIProcessingSettings.swift
//  ParentGuidance
//
//  Created by alex kerss on 29/07/2025.
//

import Foundation

/// Service for managing AI processing feature toggles
class AIProcessingSettings {
    static let shared = AIProcessingSettings()
    
    // UserDefaults keys
    private let situationAnalysisKey = "ai_processing_situation_analysis_enabled"
    private let contextExtractionKey = "ai_processing_context_extraction_enabled"
    private let regulationInsightsKey = "ai_processing_regulation_insights_enabled"
    private let copingStrategiesKey = "ai_processing_coping_strategies_enabled"
    
    private init() {
        // Set defaults if not already set
        if UserDefaults.standard.object(forKey: situationAnalysisKey) == nil {
            UserDefaults.standard.set(true, forKey: situationAnalysisKey)
        }
        if UserDefaults.standard.object(forKey: contextExtractionKey) == nil {
            UserDefaults.standard.set(true, forKey: contextExtractionKey)
        }
        if UserDefaults.standard.object(forKey: regulationInsightsKey) == nil {
            UserDefaults.standard.set(true, forKey: regulationInsightsKey)
        }
        if UserDefaults.standard.object(forKey: copingStrategiesKey) == nil {
            UserDefaults.standard.set(true, forKey: copingStrategiesKey)
        }
    }
    
    // MARK: - Getters
    
    func isSituationAnalysisEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: situationAnalysisKey)
    }
    
    func isContextExtractionEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: contextExtractionKey)
    }
    
    func isRegulationInsightsEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: regulationInsightsKey)
    }
    
    func isCopingStrategiesEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: copingStrategiesKey)
    }
    
    // MARK: - Setters
    
    func setSituationAnalysisEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: situationAnalysisKey)
        print("🔧 AI Processing: Situation Analysis set to \(enabled)")
    }
    
    func setContextExtractionEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: contextExtractionKey)
        print("🔧 AI Processing: Context Extraction set to \(enabled)")
    }
    
    func setRegulationInsightsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: regulationInsightsKey)
        print("🔧 AI Processing: Regulation Insights set to \(enabled)")
    }
    
    func setCopingStrategiesEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: copingStrategiesKey)
        print("🔧 AI Processing: Coping Strategies set to \(enabled)")
    }
    
    // MARK: - Load All Settings
    
    func loadSettings() -> (situationAnalysis: Bool, contextExtraction: Bool, regulationInsights: Bool, copingStrategies: Bool) {
        return (
            situationAnalysis: isSituationAnalysisEnabled(),
            contextExtraction: isContextExtractionEnabled(),
            regulationInsights: isRegulationInsightsEnabled(),
            copingStrategies: isCopingStrategiesEnabled()
        )
    }
    
    // MARK: - Reset to Defaults
    
    func resetToDefaults() {
        setSituationAnalysisEnabled(true)
        setContextExtractionEnabled(true)
        setRegulationInsightsEnabled(true)
        setCopingStrategiesEnabled(true)
        print("🔧 AI Processing: All settings reset to defaults (enabled)")
    }
}
