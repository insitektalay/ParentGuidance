//
//  ParentGuidanceApp.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/06/2025.
//

import SwiftUI

// Import our extracted modules
// Models are automatically available in the same module
// Services
// Managers

@main
struct ParentGuidanceApp: App {
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .onAppear {
                    applyColorScheme()
                }
        }
    }
    
    private func applyColorScheme() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        
        windowScene.windows.forEach { window in
            switch preferredColorScheme {
            case "light":
                window.overrideUserInterfaceStyle = .light
            case "dark":
                window.overrideUserInterfaceStyle = .dark
            default:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
}

