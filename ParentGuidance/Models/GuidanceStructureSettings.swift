//
//  GuidanceStructureSettings.swift
//  ParentGuidance
//
//  Created by alex kerss on 16/07/2025.
//

import Foundation
import SwiftUI

// MARK: - Guidance Structure Mode
enum GuidanceStructureMode: String, CaseIterable {
    case fixed = "fixed"
    case dynamic = "dynamic"
    
    var displayName: String {
        switch self {
        case .fixed: return "Fixed Structure"
        case .dynamic: return "Dynamic Structure"
        }
    }
    
    var description: String {
        switch self {
        case .fixed: 
            return "7 consistent sections: Situation, Analysis, Action Steps, Phrases to Try, Quick Comebacks, and Support"
        case .dynamic: 
            return "3-8 flexible sections with AI-generated titles that adapt to your specific situation"
        }
    }
    
    var benefits: String {
        switch self {
        case .fixed:
            return "Predictable structure • Consistent layout • Easy to navigate • Familiar format"
        case .dynamic:
            return "Tailored to your situation • AI-generated sections • Flexible content • Personalized guidance"
        }
    }
    
    var iconName: String {
        switch self {
        case .fixed: return "rectangle.grid.2x2.fill"
        case .dynamic: return "wand.and.stars"
        }
    }
    
    var sectionCount: String {
        switch self {
        case .fixed: return "6 sections"
        case .dynamic: return "3-8 sections"
        }
    }
}

// MARK: - Guidance Style
enum GuidanceStyle: String, CaseIterable {
    case warmPractical = "warm_practical"
    case analyticalScientific = "analytical_scientific"
    
    var displayName: String {
        switch self {
        case .warmPractical: return "Warm & Practical"
        case .analyticalScientific: return "Analytical & Scientific"
        }
    }
    
    var description: String {
        switch self {
        case .warmPractical: 
            return "Empathetic, supportive guidance with practical, actionable advice"
        case .analyticalScientific: 
            return "Evidence-based, systematic approach with research-backed strategies"
        }
    }
}

// MARK: - Settings Manager
class GuidanceStructureSettings: ObservableObject {
    static let shared = GuidanceStructureSettings()
    
    @AppStorage("guidanceStructureMode") private var storedMode: String = GuidanceStructureMode.fixed.rawValue
    @AppStorage("guidanceStyle") private var storedStyle: String = GuidanceStyle.warmPractical.rawValue
    @AppStorage("enableChildContext") private var storedChildContext: Bool = false
    @AppStorage("enableKeyInsights") private var storedKeyInsights: Bool = false
    
    private init() {
        // Private initializer to enforce singleton pattern
    }
    
    var currentMode: GuidanceStructureMode {
        get {
            return GuidanceStructureMode(rawValue: storedMode) ?? .fixed
        }
        set {
            storedMode = newValue.rawValue
            objectWillChange.send()
        }
    }
    
    var currentStyle: GuidanceStyle {
        get {
            return GuidanceStyle(rawValue: storedStyle) ?? .warmPractical
        }
        set {
            storedStyle = newValue.rawValue
            objectWillChange.send()
        }
    }
    
    var enableChildContext: Bool {
        get {
            return storedChildContext
        }
        set {
            storedChildContext = newValue
            objectWillChange.send()
        }
    }
    
    var enableKeyInsights: Bool {
        get {
            return storedKeyInsights
        }
        set {
            storedKeyInsights = newValue
            objectWillChange.send()
        }
    }
    
    var isUsingDynamicStructure: Bool {
        return currentMode == .dynamic
    }
    
    var hasEnabledPsychologistNotes: Bool {
        return enableChildContext || enableKeyInsights
    }
    
    func toggleMode() {
        currentMode = currentMode == .fixed ? .dynamic : .fixed
    }
    
    func toggleStyle() {
        currentStyle = currentStyle == .warmPractical ? .analyticalScientific : .warmPractical
    }
    
    func toggleChildContext() {
        enableChildContext.toggle()
    }
    
    func toggleKeyInsights() {
        enableKeyInsights.toggle()
    }
    
    // MARK: - Version Mapping
    
    func getPromptVersion(hasFramework: Bool) -> String {
        if hasFramework {
            // With Framework prompt: pmpt_68516f961dc08190aceb4f591ee010050a454989b0581453
            switch (currentStyle, currentMode) {
            case (.warmPractical, .fixed): return "3"
            case (.warmPractical, .dynamic): return "6"
            case (.analyticalScientific, .fixed): return "7"
            case (.analyticalScientific, .dynamic): return "8"
            }
        } else {
            // No Framework prompt: pmpt_68515280423c8193aaa00a07235b7cf206c51d869f9526ba
            switch (currentStyle, currentMode) {
            case (.warmPractical, .fixed): return "12"
            case (.warmPractical, .dynamic): return "16"
            case (.analyticalScientific, .fixed): return "19"
            case (.analyticalScientific, .dynamic): return "18"
            }
        }
    }
}
