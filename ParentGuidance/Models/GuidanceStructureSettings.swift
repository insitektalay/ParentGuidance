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
}

// MARK: - Settings Manager
class GuidanceStructureSettings: ObservableObject {
    static let shared = GuidanceStructureSettings()
    
    @AppStorage("guidanceStructureMode") private var storedMode: String = GuidanceStructureMode.fixed.rawValue
    
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
    
    var isUsingDynamicStructure: Bool {
        return currentMode == .dynamic
    }
    
    func toggleMode() {
        currentMode = currentMode == .fixed ? .dynamic : .fixed
    }
}
