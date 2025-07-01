//
//  ParentGuidanceApp.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/06/2025.
//

import SwiftUI

@main
struct ParentGuidanceApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                OnboardingFlow()
            }
        }
    }
}

struct OnboardingFlow: View {
    @State private var currentView: OnboardingStep = .welcome
    
    enum OnboardingStep {
        case welcome
        case authentication
        case main
    }
    
    var body: some View {
        switch currentView {
        case .welcome:
            WelcomeView(
                onGetStarted: {
                    currentView = .authentication
                }
            )
        case .authentication:
            AuthenticationView(
                onAppleSignIn: {
                    currentView = .main
                },
                onGoogleSignIn: {
                    currentView = .main
                },
                onFacebookSignIn: {
                    currentView = .main
                },
                onEmailSignIn: {
                    currentView = .main
                },
                onBackTapped: {
                    currentView = .welcome
                }
            )
        case .main:
            MainTabView()
        }
    }
}

