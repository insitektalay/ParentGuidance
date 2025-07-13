//
//  SettingsView.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/06/2025.
//

import SwiftUI

// MARK: - Framework State Management

class SettingsFrameworkState: ObservableObject {
    @Published var frameworks: [FrameworkRecommendation] = []
    @Published var activeFrameworkIds: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var familyId: String?
    
    @MainActor
    func loadFrameworks(familyId: String?) async {
        guard let familyId = familyId else {
            print("❌ No family ID available for SettingsFrameworkState")
            return
        }
        
        self.familyId = familyId
        isLoading = true
        errorMessage = nil
        
        do {
            // Load all frameworks for this family
            frameworks = try await FrameworkStorageService.shared.getFrameworkHistory(familyId: familyId)
            
            // Load active framework to identify which ones are active
            if let activeFramework = try await FrameworkStorageService.shared.getActiveFramework(familyId: familyId) {
                activeFrameworkIds = [activeFramework.id]
                print("✅ Settings: Loaded \(frameworks.count) frameworks, 1 active: \(activeFramework.frameworkName)")
            } else {
                activeFrameworkIds = []
                print("✅ Settings: Loaded \(frameworks.count) frameworks, none active")
            }
        } catch {
            print("❌ Settings: Failed to load frameworks: \(error)")
            errorMessage = "Unable to load frameworks"
        }
        
        isLoading = false
    }
    
    @MainActor
    func toggleFramework(frameworkId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if activeFrameworkIds.contains(frameworkId) {
                // Deactivate framework
                try await FrameworkStorageService.shared.deactivateFramework(id: frameworkId)
                activeFrameworkIds.remove(frameworkId)
                print("✅ Settings: Framework deactivated: \(frameworkId)")
            } else {
                // Activate framework
                try await FrameworkStorageService.shared.activateFramework(id: frameworkId)
                activeFrameworkIds.insert(frameworkId)
                print("✅ Settings: Framework activated: \(frameworkId)")
            }
        } catch {
            print("❌ Settings: Failed to toggle framework: \(error)")
            errorMessage = "Unable to update framework"
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
                } else if frameworkState.frameworks.isEmpty {
                    noFrameworksView
                } else {
                    frameworkListView
                }
            }
            .padding(16)
            .background(ColorPalette.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
        .onAppear {
            Task {
                await frameworkState.loadFrameworks(familyId: appCoordinator.currentUserId)
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
                    await frameworkState.loadFrameworks(familyId: appCoordinator.currentUserId)
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(ColorPalette.terracotta)
        }
    }
    
    private var frameworkListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with count
            Text("Your Frameworks (\(frameworkState.frameworks.count))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            // Framework cards
            ForEach(frameworkState.frameworks, id: \.id) { framework in
                FrameworkCard(
                    framework: framework,
                    isActive: frameworkState.activeFrameworkIds.contains(framework.id),
                    onToggle: {
                        Task {
                            await frameworkState.toggleFramework(frameworkId: framework.id)
                        }
                    },
                    onRemove: {
                        // TODO: Implement framework removal
                        print("Remove framework: \(framework.frameworkName)")
                    }
                )
            }
        }
    }
    
    private var noFrameworksView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Framework Status")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text("No frameworks set up yet")
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
            
            Text("Generate frameworks by selecting situations from your Library and tapping 'Set Up Framework'.")
                .font(.system(size: 12))
                .foregroundColor(ColorPalette.white.opacity(0.6))
                .lineLimit(nil)
            
            Button("Go to Library") {
                // TODO: Navigate to Library tab
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(ColorPalette.terracotta)
        }
    }
}

// MARK: - Framework Card Component

struct FrameworkCard: View {
    let framework: FrameworkRecommendation
    let isActive: Bool
    let onToggle: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Framework header with status
            HStack(spacing: 8) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(isActive ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.6))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(framework.frameworkName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ColorPalette.white)
                    
                    Text(isActive ? "Active" : "Inactive")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isActive ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.6))
                }
                
                Spacer()
                
                // Toggle switch
                Button(action: onToggle) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isActive ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.3))
                        .frame(width: 44, height: 24)
                        .overlay(
                            Circle()
                                .fill(ColorPalette.white)
                                .frame(width: 20, height: 20)
                                .offset(x: isActive ? 10 : -10)
                        )
                        .animation(.easeInOut(duration: 0.2), value: isActive)
                }
            }
            
            // Framework description
            Text(framework.notificationText)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.8))
                .lineLimit(2)
            
            // Framework actions
            HStack(spacing: 12) {
                Button("Framework Guide") {
                    // TODO: Navigate to framework guide
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ColorPalette.brightBlue)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Button("Remove") {
                    onRemove()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ColorPalette.terracotta)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(ColorPalette.terracotta, lineWidth: 1)
                )
                
                Spacer()
            }
        }
        .padding(12)
        .background(ColorPalette.white.opacity(isActive ? 0.08 : 0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? ColorPalette.brightBlue.opacity(0.3) : ColorPalette.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    SettingsView()
}
