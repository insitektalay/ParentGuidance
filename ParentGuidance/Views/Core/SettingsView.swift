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
    @Published var showingRemovalConfirmation: Bool = false
    @Published var frameworkToRemove: FrameworkRecommendation?
    @Published var isRemoving: Bool = false
    
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
    
    @MainActor
    func removeFramework(frameworkId: String) async {
        isRemoving = true
        errorMessage = nil
        
        do {
            // Remove from database
            try await FrameworkStorageService.shared.deleteFrameworkRecommendation(id: frameworkId)
            
            // Remove from local state
            frameworks.removeAll { $0.id == frameworkId }
            activeFrameworkIds.remove(frameworkId)
            
            print("✅ Settings: Framework removed successfully: \(frameworkId)")
            
            // Clear removal state
            frameworkToRemove = nil
            showingRemovalConfirmation = false
            
        } catch {
            print("❌ Settings: Failed to remove framework: \(error)")
            errorMessage = "Unable to remove framework"
        }
        
        isRemoving = false
    }
    
    @MainActor
    func prepareForRemoval(framework: FrameworkRecommendation) {
        frameworkToRemove = framework
        showingRemovalConfirmation = true
    }
    
    @MainActor
    func cancelRemoval() {
        frameworkToRemove = nil
        showingRemovalConfirmation = false
    }
}

struct SettingsView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @StateObject private var frameworkState = SettingsFrameworkState()
    
    // MARK: - Child Profile Edit State
    
    @State private var showingChildEdit: Bool = false
    
    // MARK: - Account Data State
    
    @State private var userProfile: UserProfile?
    @State private var isLoadingProfile: Bool = false
    @State private var showingApiKeyManagement: Bool = false
    @State private var showingSignOutConfirmation: Bool = false
    
    // MARK: - Formatting Helpers
    
    private func formatChildAge(_ child: Child?) -> String {
        guard let child = child, let age = child.age else {
            return "Not set"
        }
        
        // Handle edge cases
        if age <= 0 {
            return "Not set"
        }
        
        // Format age consistently with onboarding pattern
        if age == 1 {
            return "1 year old"
        } else {
            return "\(age) years old"
        }
    }
    
    private func formatEmailText() -> String {
        if isLoadingProfile {
            return "Loading..."
        }
        return userProfile?.email ?? "Not available"
    }
    
    private func formatPlanText() -> String {
        if isLoadingProfile {
            return "Loading..."
        }
        
        guard let plan = userProfile?.selectedPlan else {
            return "No plan selected"
        }
        
        switch plan.lowercased() {
        case "api":
            return "Bring Your Own API"
        case "basic":
            return "Basic Plan"
        case "premium":
            return "Premium Plan"
        case "family":
            return "Family Plan"
        default:
            return plan.capitalized
        }
    }
    
    private func formatApiKeyStatus() -> String {
        if isLoadingProfile {
            return "Loading..."
        }
        
        guard let profile = userProfile else {
            return "Unknown"
        }
        
        if let apiKey = profile.userApiKey, !apiKey.isEmpty {
            return "Connected (\(profile.apiKeyProvider?.capitalized ?? "OpenAI"))"
        } else if profile.selectedPlan == "api" {
            return "Not configured"
        } else {
            return "Not required"
        }
    }
    
    private func shouldShowApiKeyManagement() -> Bool {
        guard let profile = userProfile else { return false }
        return profile.selectedPlan == "api"
    }
    
    // MARK: - Sign Out Handler
    
    private func handleSignOut() {
        showingSignOutConfirmation = false
        appCoordinator.signOut()
    }
    
    // MARK: - Account Data Loading
    
    private func loadUserProfile() async {
        guard let userId = appCoordinator.currentUserId else {
            print("❌ No current user ID available for loading profile")
            return
        }
        
        await MainActor.run {
            isLoadingProfile = true
        }
        
        do {
            let profile = try await AuthService.shared.loadUserProfile(userId: userId)
            await MainActor.run {
                self.userProfile = profile
                self.isLoadingProfile = false
            }
            print("✅ Settings: User profile loaded successfully")
        } catch {
            print("❌ Settings: Failed to load user profile: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoadingProfile = false
            }
        }
    }
    
    // MARK: - Child Profile Save Handler
    
    private func handleChildSave(childId: String, name: String, age: Int?, pronouns: String?) async -> Bool {
        do {
            // Update child in database
            try await AuthService.shared.updateChild(childId: childId, name: name, age: age, pronouns: pronouns)
            
            // Refresh children data in AppCoordinator
            await appCoordinator.refreshChildren()
            
            print("✅ Child profile updated successfully")
            return true
            
        } catch {
            print("❌ Failed to save child profile: \(error.localizedDescription)")
            return false
        }
    }
    
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
        .overlay(frameworkRemovalConfirmationOverlay)
        .overlay(signOutConfirmationOverlay)
        .sheet(isPresented: $showingChildEdit) {
            if let firstChild = appCoordinator.children.first {
                ChildProfileEditView(
                    child: firstChild,
                    onSave: { name, age, pronouns in
                        await handleChildSave(childId: firstChild.id, name: name, age: age, pronouns: pronouns)
                    }
                )
            } else {
                Text("ERROR: No child data")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .sheet(isPresented: $showingApiKeyManagement) {
            if let profile = userProfile {
                NavigationView {
                    VStack {
                        Text("API Key Management")
                            .font(.title2)
                            .foregroundColor(ColorPalette.white)
                            .padding()
                        
                        Text("API Key management functionality coming soon")
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                            .padding()
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(ColorPalette.navy)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                showingApiKeyManagement = false
                            }
                            .foregroundColor(ColorPalette.white)
                        }
                    }
                }
            }
        }
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
                await loadUserProfile()
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
                    
                    Text(formatChildAge(appCoordinator.children.first))
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                Button("Edit Profile") {
                    if appCoordinator.children.first != nil {
                        showingChildEdit = true
                    }
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
                    
                    Text(formatEmailText())
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                HStack {
                    Text("Plan")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text(formatPlanText())
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                HStack {
                    Text("API Key")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text(formatApiKeyStatus())
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                if shouldShowApiKeyManagement() {
                    Button("Manage API Key") {
                        showingApiKeyManagement = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorPalette.terracotta)
                }
                
                Button("Sign Out") {
                    showingSignOutConfirmation = true
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
                        frameworkState.prepareForRemoval(framework: framework)
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
    
    // MARK: - Sign Out Confirmation
    
    private var signOutConfirmationOverlay: some View {
        Group {
            if showingSignOutConfirmation {
                ZStack {
                    // Semi-transparent background
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingSignOutConfirmation = false
                        }
                    
                    // Confirmation dialog
                    ConfirmationDialog(
                        title: "Sign Out",
                        message: "Are you sure you want to sign out? You'll need to sign in again to access your account.",
                        destructiveButtonTitle: "Sign Out",
                        onDestruct: {
                            handleSignOut()
                        },
                        onCancel: {
                            showingSignOutConfirmation = false
                        }
                    )
                }
                .zIndex(3000)
            }
        }
    }
    
    // MARK: - Framework Removal Confirmation
    
    private var frameworkRemovalConfirmationOverlay: some View {
        Group {
            if frameworkState.showingRemovalConfirmation {
                ZStack {
                    // Semi-transparent background
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            frameworkState.cancelRemoval()
                        }
                    
                    // Confirmation dialog
                    ConfirmationDialog(
                        title: "Remove Framework",
                        message: "Are you sure you want to permanently remove this framework? This action cannot be undone.",
                        destructiveButtonTitle: frameworkState.isRemoving ? "Removing..." : "Remove",
                        onDestruct: {
                            if let framework = frameworkState.frameworkToRemove {
                                Task {
                                    await frameworkState.removeFramework(frameworkId: framework.id)
                                }
                            }
                        },
                        onCancel: {
                            frameworkState.cancelRemoval()
                        }
                    )
                }
                .zIndex(2000)
            }
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
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(ColorPalette.brightBlue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Button("Remove") {
                    onRemove()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorPalette.terracotta)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorPalette.terracotta, lineWidth: 1)
                )
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            Color(red: 0.21, green: 0.22, blue: 0.33)
                .opacity(isActive ? 1.0 : 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? ColorPalette.brightBlue.opacity(0.3) : ColorPalette.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    SettingsView()
}
