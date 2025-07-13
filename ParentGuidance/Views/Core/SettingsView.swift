//
//  SettingsView.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/06/2025.
//

import SwiftUI

// MARK: - Framework State Management

class SettingsFrameworkState: ObservableObject {
    @Published var currentFramework: FrameworkRecommendation?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var familyId: String?
    
    @MainActor
    func loadFramework(familyId: String?) async {
        guard let familyId = familyId else {
            print("❌ No family ID available for SettingsFrameworkState")
            return
        }
        
        self.familyId = familyId
        isLoading = true
        errorMessage = nil
        
        do {
            currentFramework = try await FrameworkStorageService.shared.getActiveFramework(familyId: familyId)
            if let framework = currentFramework {
                print("✅ Settings: Loaded active framework: \(framework.frameworkName)")
            } else {
                print("📭 Settings: No active framework found")
            }
        } catch {
            print("❌ Settings: Failed to load framework: \(error)")
            errorMessage = "Unable to load framework status"
        }
        
        isLoading = false
    }
    
    @MainActor
    func deactivateFramework() async {
        guard let framework = currentFramework else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await FrameworkStorageService.shared.deactivateFramework(id: framework.id)
            currentFramework = nil
            print("✅ Settings: Framework deactivated: \(framework.frameworkName)")
        } catch {
            print("❌ Settings: Failed to deactivate framework: \(error)")
            errorMessage = "Unable to deactivate framework"
        }
        
        isLoading = false
    }
}

struct SettingsView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @StateObject private var frameworkState = SettingsFrameworkState()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Settings title
                Text("Settings")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(ColorPalette.white)
                    .padding(.horizontal, 16)
                
                // Foundation Tools Section
                foundationToolsSection
                
                // Child Profile Section
                childProfileSection
                
                // Account Section
                accountSection
                
                // Privacy & Data Section
                privacyDataSection
                
                // Help & Support Section
                helpSupportSection
            }
            .padding(.top, 16)
            .padding(.bottom, 100) // Space for tab bar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
    }
    
    // MARK: - Section Views
    
    private var foundationToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Foundation Tools")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                if frameworkState.isLoading {
                    loadingFrameworkView
                } else if let errorMessage = frameworkState.errorMessage {
                    errorFrameworkView(errorMessage)
                } else if let framework = frameworkState.currentFramework {
                    activeFrameworkView(framework)
                } else {
                    inactiveFrameworkView
                }
            }
            .padding(16)
            .background(ColorPalette.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
        .onAppear {
            Task {
                await frameworkState.loadFramework(familyId: appCoordinator.currentUserId)
            }
        }
    }
    
    private var childProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Child Profile")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Child Name")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text(appCoordinator.children.first?.name ?? "Not set")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                HStack {
                    Text("Age")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text("Not set")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                Button("Edit Profile") {
                    // TODO: Navigate to child profile editing
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorPalette.terracotta)
            }
            .padding(16)
            .background(ColorPalette.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Email")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text("Loading...")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                HStack {
                    Text("Subscription")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text("Free Plan")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                Button("Sign Out") {
                    // TODO: Handle sign out
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorPalette.terracotta)
            }
            .padding(16)
            .background(ColorPalette.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }
    
    private var privacyDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy & Data")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                Button("Export My Data") {
                    // TODO: Handle data export
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button("Privacy Policy") {
                    // TODO: Show privacy policy
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button("Delete Account") {
                    // TODO: Handle account deletion
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.terracotta)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(ColorPalette.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }
    
    private var helpSupportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Help & Support")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                Button("Documentation") {
                    // TODO: Open documentation
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button("Contact Support") {
                    // TODO: Open support contact
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Text("App Version")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text("1.0.0")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
            }
            .padding(16)
            .background(ColorPalette.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Framework State Views
    
    private var loadingFrameworkView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(ColorPalette.white)
            
            Text("Loading framework status...")
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
        }
    }
    
    private func errorFrameworkView(_ errorMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Unable to load framework status")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(errorMessage)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
            
            Button("Try Again") {
                Task {
                    await frameworkState.loadFramework(familyId: appCoordinator.currentUserId)
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(ColorPalette.terracotta)
        }
    }
    
    private func activeFrameworkView(_ framework: FrameworkRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Active framework header
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(ColorPalette.brightBlue)
                
                Text("Active Framework")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ColorPalette.brightBlue)
                
                Spacer()
            }
            
            // Framework details
            VStack(alignment: .leading, spacing: 8) {
                Text(framework.frameworkName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ColorPalette.white)
                
                Text(framework.notificationText)
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.white.opacity(0.8))
                    .lineLimit(3)
            }
            
            // Framework actions
            HStack(spacing: 12) {
                Button("Framework Guide") {
                    // TODO: Navigate to framework guide
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(ColorPalette.brightBlue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Button("Deactivate") {
                    Task {
                        await frameworkState.deactivateFramework()
                    }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorPalette.terracotta)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorPalette.terracotta, lineWidth: 1)
                )
                
                Spacer()
            }
        }
    }
    
    private var inactiveFrameworkView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Framework Status")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text("No active framework currently set up")
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
            
            Button("View Framework Tools") {
                // TODO: Navigate to framework tools
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(ColorPalette.terracotta)
        }
    }
}

#Preview {
    SettingsView()
}
