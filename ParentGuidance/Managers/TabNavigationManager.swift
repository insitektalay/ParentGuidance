//
//  TabNavigationManager.swift
//  ParentGuidance
//
//  Created by alex kerss on 07/07/2025.
//

import Foundation
import Combine

class TabNavigationManager: ObservableObject {
    static let shared = TabNavigationManager()
    
    @Published var requestedTab: Tab?
    
    private init() {}
    
    /// Request navigation to a specific tab
    func navigateToTab(_ tab: Tab) {
        print("📱 Navigation requested to tab: \(tab.title)")
        requestedTab = tab
    }
    
    /// Clear the navigation request after handling
    func clearNavigationRequest() {
        requestedTab = nil
    }
}