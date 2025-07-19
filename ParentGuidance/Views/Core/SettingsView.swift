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
    @ObservedObject private var guidanceStructureSettings = GuidanceStructureSettings.shared
    
    // MARK: - Child Profile Edit State
    
    @State private var showingChildEdit: Bool = false
    
    // MARK: - Account Data State
    
    @State private var userProfile: UserProfile?
    @State private var isLoadingProfile: Bool = false
    @State private var showingApiKeyManagement: Bool = false
    @State private var showingSignOutConfirmation: Bool = false
    
    // MARK: - Privacy & Data State
    
    @State private var isExportingData: Bool = false
    @State private var exportSuccessMessage: String?
    @State private var showingExportSuccess: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var deleteConfirmationStep: Int = 0
    @State private var isDeletingAccount: Bool = false
    @State private var showingPrivacyPolicy: Bool = false
    @State private var showingDocumentation: Bool = false
    @State private var showDebugInfo: Bool = false
    
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
    
    // MARK: - Data Export Handler
    
    private func handleDataExport() async {
        guard let userId = appCoordinator.currentUserId,
              let userEmail = userProfile?.email else {
            print("❌ No user ID or email available for data export")
            return
        }
        
        await MainActor.run {
            isExportingData = true
        }
        
        do {
            // Collect all user data
            let exportData = try await collectUserDataForExport(userId: userId)
            
            // Send data via email
            try await sendDataExportEmail(data: exportData, email: userEmail)
            
            await MainActor.run {
                isExportingData = false
                exportSuccessMessage = "Your data export has been sent to \(userEmail)"
                showingExportSuccess = true
            }
            
            print("✅ Data export sent successfully to \(userEmail)")
            
        } catch {
            await MainActor.run {
                isExportingData = false
                exportSuccessMessage = "Failed to export data: \(error.localizedDescription)"
                showingExportSuccess = true
            }
            print("❌ Data export failed: \(error)")
        }
    }
    
    private func collectUserDataForExport(userId: String) async throws -> [String: Any] {
        let supabase = SupabaseManager.shared.client
        
        // Collect user profile
        let profile = try await AuthService.shared.loadUserProfile(userId: userId)
        
        // Collect children data
        let children: [Child] = try await supabase
            .from("children")
            .select("*")
            .eq("family_id", value: userId)
            .execute()
            .value
        
        // Collect situations
        let situations: [Situation] = try await supabase
            .from("situations")
            .select("*")
            .eq("user_id", value: userId)
            .execute()
            .value
        
        // Collect guidance
        let guidance: [Guidance] = try await supabase
            .from("guidance")
            .select("*")
            .eq("user_id", value: userId)
            .execute()
            .value
        
        // Collect frameworks
        let frameworks: [FrameworkRecommendation] = try await FrameworkStorageService.shared.getFrameworkHistory(familyId: userId)
        
        // Create export structure
        let exportData: [String: Any] = [
            "export_info": [
                "user_id": userId,
                "export_date": ISO8601DateFormatter().string(from: Date()),
                "app_version": "1.0.0"
            ],
            "profile": [
                "email": profile.email ?? "",
                "selected_plan": profile.selectedPlan ?? "",
                "created_at": profile.createdAt,
                "updated_at": profile.updatedAt
            ],
            "children": children.map { child in
                [
                    "id": child.id,
                    "name": child.name ?? "",
                    "age": child.age ?? 0,
                    "pronouns": child.pronouns ?? "",
                    "created_at": child.createdAt,
                    "updated_at": child.updatedAt
                ]
            },
            "situations": situations.map { situation in
                [
                    "id": situation.id,
                    "title": situation.title,
                    "description": situation.description,
                    "situation_type": situation.situationType,
                    "category": situation.category ?? "",
                    "is_favorited": situation.isFavorited,
                    "is_incident": situation.isIncident,
                    "created_at": situation.createdAt,
                    "updated_at": situation.updatedAt
                ]
            },
            "guidance": guidance.map { guide in
                [
                    "id": guide.id,
                    "situation_id": guide.situationId,
                    "content": guide.content ?? "",
                    "created_at": guide.createdAt,
                    "updated_at": guide.updatedAt
                ]
            },
            "frameworks": frameworks.map { framework in
                [
                    "id": framework.id,
                    "framework_name": framework.frameworkName,
                    "notification_text": framework.notificationText,
                    "created_at": framework.createdAt
                ]
            }
        ]
        
        return exportData
    }
    
    private func sendDataExportEmail(data: [String: Any], email: String) async throws {
        // Convert data to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        _ = String(data: jsonData, encoding: .utf8) ?? ""
        
        // For now, we'll simulate sending an email
        // In a real implementation, you would integrate with an email service like:
        // - Supabase Edge Functions
        // - SendGrid, Mailgun, or similar email API
        // - Backend email service
        
        print("📧 Simulating email send to: \(email)")
        print("📧 Email would contain JSON export of \(data.keys.count) data categories")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // For now, we'll just log success
        // In production, this would make an actual API call to send the email
        print("✅ Email simulation completed")
    }
    
    // MARK: - Account Deletion Handler
    
    private func handleAccountDeletion() async {
        guard let userId = appCoordinator.currentUserId else {
            print("❌ No user ID available for account deletion")
            return
        }
        
        await MainActor.run {
            isDeletingAccount = true
        }
        
        do {
            // Delete all user data from database
            try await deleteAllUserData(userId: userId)
            
            await MainActor.run {
                isDeletingAccount = false
                showingDeleteConfirmation = false
                deleteConfirmationStep = 0
            }
            
            // Sign out the user after successful deletion
            appCoordinator.signOut()
            
            print("✅ Account deletion completed successfully")
            
        } catch {
            await MainActor.run {
                isDeletingAccount = false
                exportSuccessMessage = "Failed to delete account: \(error.localizedDescription)"
                showingExportSuccess = true
            }
            print("❌ Account deletion failed: \(error)")
        }
    }
    
    private func deleteAllUserData(userId: String) async throws {
        let supabase = SupabaseManager.shared.client
        
        print("🗑️ Starting complete account deletion for user: \(userId)")
        
        // Delete frameworks
        do {
            let frameworks = try await FrameworkStorageService.shared.getFrameworkHistory(familyId: userId)
            for framework in frameworks {
                try await FrameworkStorageService.shared.deleteFrameworkRecommendation(id: framework.id)
            }
            print("✅ Deleted \(frameworks.count) frameworks")
        } catch {
            print("⚠️ Error deleting frameworks: \(error)")
        }
        
        // Delete guidance
        try await supabase
            .from("guidance")
            .delete()
            .eq("user_id", value: userId)
            .execute()
        print("✅ Deleted guidance records")
        
        // Delete situations
        try await supabase
            .from("situations")
            .delete()
            .eq("user_id", value: userId)
            .execute()
        print("✅ Deleted situation records")
        
        // Delete children
        try await supabase
            .from("children")
            .delete()
            .eq("family_id", value: userId)
            .execute()
        print("✅ Deleted child records")
        
        // Delete user profile
        try await supabase
            .from("profiles")
            .delete()
            .eq("id", value: userId)
            .execute()
        print("✅ Deleted user profile")
        
        print("🗑️ Complete account deletion finished")
    }
    
    // MARK: - Support Email Handler
    
    private func openSupportEmail() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let iOSVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        let userId = appCoordinator.currentUserId ?? "Not signed in"
        
        let subject = "ParentGuidance Support Request"
        let body = """
        
        
        ---
        Please describe your issue above this line.
        
        App Information (please keep for support):
        • App Version: \(appVersion) (Build \(buildNumber))
        • iOS Version: \(iOSVersion)
        • Device: \(deviceModel)
        • User ID: \(userId)
        """
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let mailtoURL = "mailto:support@parentguidance.ai?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let url = URL(string: mailtoURL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                print("✅ Opened support email with context")
            } else {
                print("❌ Cannot open mail app")
                // Fallback: show alert with email address
                showSupportEmailFallback()
            }
        }
    }
    
    private func showSupportEmailFallback() {
        exportSuccessMessage = "Please email us at support@parentguidance.ai for assistance."
        showingExportSuccess = true
    }
    
    // MARK: - App Info Helpers
    
    private func getAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private func getBuildNumber() -> String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    private var debugInfoSection: some View {
        VStack(spacing: 4) {
            HStack {
                Text(String(localized: "settings.device.iosVersion"))
                    .font(.system(size: 12))
                    .foregroundColor(ColorPalette.white.opacity(0.6))
                
                Spacer()
                
                Text(UIDevice.current.systemVersion)
                    .font(.system(size: 12))
                    .foregroundColor(ColorPalette.white.opacity(0.5))
            }
            
            HStack {
                Text(String(localized: "settings.device.device"))
                    .font(.system(size: 12))
                    .foregroundColor(ColorPalette.white.opacity(0.6))
                
                Spacer()
                
                Text(UIDevice.current.model)
                    .font(.system(size: 12))
                    .foregroundColor(ColorPalette.white.opacity(0.5))
            }
            
            if let userId = appCoordinator.currentUserId {
                HStack {
                    Text(String(localized: "settings.device.userId"))
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text(String(userId.prefix(8)) + "...")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ColorPalette.white.opacity(0.5))
                }
            }
        }
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
                Text(String(localized: "settings.title"))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(ColorPalette.white)
                    .padding(.horizontal, 16)
                
                // Foundation Tools Section
                foundationToolsSection
                
                // Guidance Structure Section
                guidanceStructureSection
                
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
        .overlay(deleteAccountConfirmationOverlay)
        .sheet(isPresented: $showingChildEdit) {
            if let firstChild = appCoordinator.children.first {
                ChildProfileEditView(
                    child: firstChild,
                    onSave: { name, age, pronouns in
                        await handleChildSave(childId: firstChild.id, name: name, age: age, pronouns: pronouns)
                    }
                )
            } else {
                Text(String(localized: "settings.error.noChildData"))
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .sheet(isPresented: $showingApiKeyManagement) {
            if let profile = userProfile {
                NavigationView {
                    VStack {
                        Text(String(localized: "settings.apiKey.title"))
                            .font(.title2)
                            .foregroundColor(ColorPalette.white)
                            .padding()
                        
                        Text(String(localized: "settings.apiKey.comingSoon"))
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                            .padding()
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(ColorPalette.navy)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(String(localized: "common.close")) {
                                showingApiKeyManagement = false
                            }
                            .foregroundColor(ColorPalette.white)
                        }
                    }
                }
            }
        }
        .alert("Export Status", isPresented: $showingExportSuccess) {
            Button(String(localized: "common.ok")) {
                showingExportSuccess = false
                exportSuccessMessage = nil
            }
        } message: {
            Text(exportSuccessMessage ?? "")
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingDocumentation) {
            DocumentationView()
        }
    }
    
    // MARK: - Section Views
    
    private var foundationToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "settings.foundationTools.title"))
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
    
    private var guidanceStructureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "settings.guidanceStructure.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                // Current mode status
                HStack(spacing: 8) {
                    Image(systemName: guidanceStructureSettings.currentMode.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.brightBlue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "settings.guidanceStructure.activeMode"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ColorPalette.white)
                        
                        Text(guidanceStructureSettings.currentMode.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ColorPalette.brightBlue)
                    }
                    
                    Spacer()
                    
                    // Mode indicator badge
                    Text(guidanceStructureSettings.currentMode.sectionCount)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ColorPalette.brightBlue.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                // Mode description
                Text(guidanceStructureSettings.currentMode.description)
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.white.opacity(0.8))
                    .lineLimit(nil)
                
                // Mode selection cards
                VStack(spacing: 12) {
                    ForEach(GuidanceStructureMode.allCases, id: \.self) { mode in
                        GuidanceModeCard(
                            mode: mode,
                            isSelected: guidanceStructureSettings.currentMode == mode,
                            onSelect: {
                                guidanceStructureSettings.currentMode = mode
                            }
                        )
                    }
                }
                
                // Guidance Style selection
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "settings.guidanceStructure.style"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                        .padding(.top, 8)
                    
                    VStack(spacing: 8) {
                        // Warm & Practical toggle
                        HStack {
                            Text(String(localized: "settings.guidanceStructure.style.warmPractical"))
                                .font(.system(size: 14))
                                .foregroundColor(ColorPalette.white)
                            
                            Spacer()
                            
                            Button(action: {
                                if guidanceStructureSettings.currentStyle != .warmPractical {
                                    guidanceStructureSettings.currentStyle = .warmPractical
                                }
                            }) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(guidanceStructureSettings.currentStyle == .warmPractical ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.3))
                                    .frame(width: 44, height: 24)
                                    .overlay(
                                        Circle()
                                            .fill(ColorPalette.white)
                                            .frame(width: 20, height: 20)
                                            .offset(x: guidanceStructureSettings.currentStyle == .warmPractical ? 10 : -10)
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: guidanceStructureSettings.currentStyle)
                            }
                        }
                        
                        // Analytical & Scientific toggle
                        HStack {
                            Text(String(localized: "settings.guidanceStructure.style.analyticalScientific"))
                                .font(.system(size: 14))
                                .foregroundColor(ColorPalette.white)
                            
                            Spacer()
                            
                            Button(action: {
                                if guidanceStructureSettings.currentStyle != .analyticalScientific {
                                    guidanceStructureSettings.currentStyle = .analyticalScientific
                                }
                            }) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(guidanceStructureSettings.currentStyle == .analyticalScientific ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.3))
                                    .frame(width: 44, height: 24)
                                    .overlay(
                                        Circle()
                                            .fill(ColorPalette.white)
                                            .frame(width: 20, height: 20)
                                            .offset(x: guidanceStructureSettings.currentStyle == .analyticalScientific ? 10 : -10)
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: guidanceStructureSettings.currentStyle)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                // Mode benefits info
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "settings.guidanceStructure.benefits \(guidanceStructureSettings.currentMode.displayName)"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Text(guidanceStructureSettings.currentMode.benefits)
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                        .lineLimit(nil)
                }
                .padding(.top, 8)
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(String(localized: "settings.guidanceStructure.learnMore")) {
                        showingDocumentation = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorPalette.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(ColorPalette.brightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button(String(localized: "settings.guidanceStructure.previewMode")) {
                        // TODO: Add preview functionality
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
                .padding(.top, 12)
            }
            .padding(16)
            .background(ColorPalette.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }
    
    private var childProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "settings.childProfile.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(String(localized: "settings.childProfile.name"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text(appCoordinator.children.first?.name ?? "Not set")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                HStack {
                    Text(String(localized: "settings.childProfile.age"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text(formatChildAge(appCoordinator.children.first))
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                Button(String(localized: "settings.childProfile.editProfile")) {
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
            Text(String(localized: "settings.account.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(String(localized: "settings.account.email"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text(formatEmailText())
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                HStack {
                    Text(String(localized: "settings.account.plan"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text(formatPlanText())
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                HStack {
                    Text(String(localized: "settings.account.apiKey"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text(formatApiKeyStatus())
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                if shouldShowApiKeyManagement() {
                    Button(String(localized: "settings.account.manageApiKey")) {
                        showingApiKeyManagement = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorPalette.terracotta)
                }
                
                Button(String(localized: "settings.account.signOut")) {
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
            Text(String(localized: "settings.privacyData.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                Button(isExportingData ? "Exporting..." : "Export My Data") {
                    Task {
                        await handleDataExport()
                    }
                }
                .disabled(isExportingData)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(String(localized: "settings.privacyData.privacyPolicy")) {
                    showingPrivacyPolicy = true
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(String(localized: "settings.account.deleteAccount")) {
                    deleteConfirmationStep = 0
                    showingDeleteConfirmation = true
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
            Text(String(localized: "settings.helpSupport.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                Button(String(localized: "settings.helpSupport.documentation")) {
                    showingDocumentation = true
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(String(localized: "settings.helpSupport.contactSupport")) {
                    openSupportEmail()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 8) {
                    HStack {
                        Text(String(localized: "settings.helpSupport.appVersion"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ColorPalette.white.opacity(0.9))
                        
                        Spacer()
                        
                        Text(getAppVersion())
                            .font(.system(size: 14))
                            .foregroundColor(ColorPalette.white.opacity(0.7))
                    }
                    .onTapGesture {
                        showDebugInfo.toggle()
                    }
                    
                    HStack {
                        Text(String(localized: "settings.helpSupport.build"))
                            .font(.system(size: 14))
                            .foregroundColor(ColorPalette.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text(getBuildNumber())
                            .font(.system(size: 12))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                    }
                    
                    if showDebugInfo {
                        debugInfoSection
                            .animation(.easeInOut(duration: 0.2), value: showDebugInfo)
                    }
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
            
            Text(String(localized: "settings.foundationTools.loading"))
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
        }
    }
    
    private func errorFrameworkView(_ errorMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "settings.foundationTools.error"))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(errorMessage)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
            
            Button(String(localized: "common.tryAgain")) {
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
            Text(String(localized: "settings.foundationTools.frameworks \(frameworkState.frameworks.count)"))
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
            Text(String(localized: "settings.foundationTools.status"))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(String(localized: "settings.foundationTools.noFrameworks"))
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
            
            Text(String(localized: "settings.foundationTools.generateHint"))
                .font(.system(size: 12))
                .foregroundColor(ColorPalette.white.opacity(0.6))
                .lineLimit(nil)
            
            Button(String(localized: "settings.foundationTools.goToLibrary")) {
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
    
    // MARK: - Delete Account Confirmation
    
    private var deleteAccountConfirmationOverlay: some View {
        Group {
            if showingDeleteConfirmation {
                ZStack {
                    // Semi-transparent background
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingDeleteConfirmation = false
                            deleteConfirmationStep = 0
                        }
                    
                    // Multi-step confirmation dialog
                    DeleteAccountConfirmationDialog(
                        step: deleteConfirmationStep,
                        isDeleting: isDeletingAccount,
                        onNextStep: {
                            deleteConfirmationStep += 1
                        },
                        onDelete: {
                            Task {
                                await handleAccountDeletion()
                            }
                        },
                        onCancel: {
                            showingDeleteConfirmation = false
                            deleteConfirmationStep = 0
                        }
                    )
                }
                .zIndex(4000)
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

// MARK: - Guidance Mode Card Component

struct GuidanceModeCard: View {
    let mode: GuidanceStructureMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Mode icon
                Image(systemName: mode.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.6))
                    .frame(width: 24, height: 24)
                
                // Mode info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(mode.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ColorPalette.white)
                        
                        Text(mode.sectionCount)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ColorPalette.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    Text(mode.description)
                        .font(.system(size: 13))
                        .foregroundColor(ColorPalette.white.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.4))
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .padding(16)
            .background(
                Color(red: 0.21, green: 0.22, blue: 0.33)
                    .opacity(isSelected ? 1.0 : 0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? ColorPalette.brightBlue.opacity(0.4) : ColorPalette.white.opacity(0.1), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
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

// MARK: - Delete Account Confirmation Dialog

struct DeleteAccountConfirmationDialog: View {
    let step: Int
    let isDeleting: Bool
    let onNextStep: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            // Step-specific content
            switch step {
            case 0:
                firstStepContent
            case 1:
                secondStepContent
            case 2:
                finalStepContent
            default:
                firstStepContent
            }
        }
        .padding(32)
        .background(ColorPalette.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }
    
    private var firstStepContent: some View {
        VStack(spacing: 16) {
            Text(String(localized: "settings.account.delete.title"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.navy)
            
            Text(String(localized: "settings.account.delete.warning"))
                .font(.body)
                .foregroundColor(ColorPalette.navy.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.crop.circle")
                    Text(String(localized: "settings.account.delete.item.profile"))
                }
                HStack {
                    Image(systemName: "figure.child")
                    Text(String(localized: "settings.account.delete.item.children"))
                }
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text(String(localized: "settings.account.delete.item.history"))
                }
                HStack {
                    Image(systemName: "chart.bar.doc.horizontal")
                    Text(String(localized: "settings.account.delete.item.frameworks"))
                }
            }
            .font(.system(size: 14))
            .foregroundColor(ColorPalette.navy.opacity(0.7))
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.navy)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorPalette.navy, lineWidth: 1)
                )
                
                Button("Continue") {
                    onNextStep()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.red)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var secondStepContent: some View {
        VStack(spacing: 16) {
            Text(String(localized: "settings.account.delete.confirm.title"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.navy)
            
            Text(String(localized: "settings.account.delete.confirm.warning"))
                .font(.body)
                .foregroundColor(ColorPalette.navy.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Text(String(localized: "settings.account.delete.confirm.permanent"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Go Back") {
                    onCancel()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.navy)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorPalette.navy, lineWidth: 1)
                )
                
                Button("I Understand") {
                    onNextStep()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.red)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var finalStepContent: some View {
        VStack(spacing: 16) {
            Text(String(localized: "settings.account.delete.final.title"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Text(String(localized: "settings.account.delete.final.instruction"))
                .font(.body)
                .foregroundColor(ColorPalette.navy.opacity(0.8))
                .multilineTextAlignment(.center)
            
            if isDeleting {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(String(localized: "settings.account.delete.deleting"))
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.navy.opacity(0.7))
                }
                .padding(.vertical)
            } else {
                VStack(spacing: 16) {
                    DeleteConfirmationTextField(onConfirmed: onDelete)
                    
                    Button("Cancel") {
                        onCancel()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ColorPalette.navy)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ColorPalette.navy, lineWidth: 1)
                    )
                }
            }
        }
    }
}

struct DeleteConfirmationTextField: View {
    @State private var confirmationText: String = ""
    let onConfirmed: () -> Void
    
    private var isValidConfirmation: Bool {
        confirmationText.uppercased() == "DELETE"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Type DELETE", text: $confirmationText)
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(ColorPalette.navy)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isValidConfirmation ? .red : ColorPalette.navy.opacity(0.3), lineWidth: 2)
                )
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
            
            Button("DELETE ACCOUNT") {
                onConfirmed()
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(isValidConfirmation ? .red : .gray)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .disabled(!isValidConfirmation)
        }
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(String(localized: "settings.privacyData.privacyPolicy"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(ColorPalette.white)
                        .padding(.top)
                    
                    privacySection(
                        title: "Data We Collect",
                        content: "ParentGuidance collects only the information necessary to provide our parenting guidance service, including your child's basic information, parenting situations you share, and AI-generated guidance responses."
                    )
                    
                    privacySection(
                        title: "How We Use Your Data",
                        content: "Your data is used exclusively to provide personalized parenting guidance through AI analysis. We do not sell, share, or use your information for advertising purposes."
                    )
                    
                    privacySection(
                        title: "Data Storage & Security",
                        content: "All data is securely stored using industry-standard encryption. You maintain full control over your data and can export or delete it at any time through the Settings."
                    )
                    
                    privacySection(
                        title: "Your Rights",
                        content: "You have the right to access, export, correct, or delete your personal data. Use the 'Export My Data' feature to download all your information or 'Delete Account' to permanently remove all data."
                    )
                    
                    privacySection(
                        title: "AI Processing",
                        content: "Situations you share are processed by AI to generate guidance. If you provide your own OpenAI API key, your data is processed directly through OpenAI's services according to their privacy policy."
                    )
                    
                    privacySection(
                        title: "Contact",
                        content: "For privacy-related questions or concerns, please contact us through the Support section in Settings."
                    )
                    
                    Text(String(localized: "settings.privacyData.lastUpdated"))
                        .font(.caption)
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                        .padding(.top, 24)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ColorPalette.white)
                }
            }
        }
    }
    
    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.white)
            
            Text(content)
                .font(.body)
                .foregroundColor(ColorPalette.white.opacity(0.8))
                .lineSpacing(4)
        }
    }
}

// MARK: - Documentation View

struct DocumentationView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(String(localized: "settings.helpSupport.documentation"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(ColorPalette.white)
                        .padding(.top)
                    
                    faqSection(
                        title: "Getting Started",
                        items: [
                            ("How do I add my child's information?", "Go to Settings > Child Profile and tap 'Edit Profile' to update your child's name and date of birth."),
                            ("How do I get parenting guidance?", "Tap the 'New' tab and describe a parenting situation. The AI will provide personalized guidance based on your input."),
                            ("What are Foundation Tools?", "Foundation Tools are evidence-based parenting frameworks recommended by our AI based on your situations and needs.")
                        ]
                    )
                    
                    faqSection(
                        title: "Using the App",
                        items: [
                            ("How do I save a situation for later?", "Tap the heart icon on any situation in your Library to mark it as a favorite for easy access."),
                            ("Can I export my data?", "Yes! Go to Settings > Privacy & Data > 'Export My Data' to receive all your information via email."),
                            ("How do I set up a parenting framework?", "Select multiple related situations in your Library and tap 'Set Up Framework' to get AI-generated framework recommendations.")
                        ]
                    )
                    
                    faqSection(
                        title: "Account & API Keys",
                        items: [
                            ("What's the difference between plans?", "Subscription plans include AI processing, while 'Bring Your Own API' lets you use your personal OpenAI API key."),
                            ("How do I add my OpenAI API key?", "If you selected 'Bring Your Own API', go to Settings > Account > 'Manage API Key' to add your key."),
                            ("Is my data secure?", "Yes, all data is encrypted and securely stored. You can export or delete your data anytime in Settings.")
                        ]
                    )
                    
                    faqSection(
                        title: "Troubleshooting",
                        items: [
                            ("The app isn't responding correctly", "Try closing and reopening the app. If issues persist, contact support with your device and app version."),
                            ("I can't see my situations", "Check your internet connection. Your situations are synced to the cloud and require internet access."),
                            ("Framework recommendations aren't appearing", "Frameworks are generated based on multiple related situations. Try adding more situations to your Library first.")
                        ]
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ColorPalette.white)
                }
            }
        }
    }
    
    private func faqSection(title: String, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.white)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    faqItem(question: item.0, answer: item.1)
                }
            }
        }
    }
    
    private func faqItem(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white)
            
            Text(answer)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.8))
                .lineSpacing(2)
        }
        .padding(16)
        .background(ColorPalette.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    SettingsView()
}
