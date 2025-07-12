//
//  AppCoordinatorView.swift
//  ParentGuidance
//
//  Created by alex kerss on 10/07/2025.
//

import SwiftUI

struct AppCoordinatorView: View {
    @StateObject private var appCoordinator = AppCoordinator()
    
    var body: some View {
        content
            .onAppear {
                print("🚀 AppCoordinatorView appeared - current state: \(appCoordinator.currentState)")
            }
    }
    
    @ViewBuilder
    private var content: some View {
        switch appCoordinator.currentState {
        case .loading:
            LoadingView()
            
        case .onboarding(let step):
            NavigationStack {
                OnboardingFlow(step: step)
                    .environmentObject(appCoordinator)
            }
            
        case .mainApp:
            NavigationStack {
                MainTabView()
                    .environmentObject(appCoordinator)
            }
        }
    }
}

#Preview {
    AppCoordinatorView()
        .environmentObject(AppCoordinator())
}