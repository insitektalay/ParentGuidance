//
//  SettingsView.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/06/2025.
//

import SwiftUI


struct SettingsView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @StateObject private var frameworkState = SettingsFrameworkState()
    @StateObject private var viewState = SettingsViewState()
    @ObservedObject private var guidanceStructureSettings = GuidanceStructureSettings.shared
    
    // Services
    private let dataService = SettingsDataService.shared
    private let accountService = SettingsAccountService.shared
    private let formatterService = SettingsFormatterService.shared
    private let utilityService = SettingsUtilityService.shared
    
    // MARK: - Formatting Helpers (delegated to service)
    
    private func formatChildAge(_ child: Child?) -> String {
        formatterService.formatChildAge(child)
    }
    
    private func formatEmailText() -> String {
        formatterService.formatEmailText(userProfile: viewState.userProfile, isLoading: viewState.isLoadingProfile)
    }
    
    private func formatPlanText() -> String {
        formatterService.formatPlanText(userProfile: viewState.userProfile, isLoading: viewState.isLoadingProfile)
    }
    
    private func formatApiKeyStatus() -> String {
        formatterService.formatApiKeyStatus(userProfile: viewState.userProfile, isLoading: viewState.isLoadingProfile)
    }
    
    private func formatLanguageText() -> String {
        formatterService.formatLanguageText(userProfile: viewState.userProfile, isLoading: viewState.isLoadingProfile)
    }
    
    private func shouldShowApiKeyManagement() -> Bool {
        utilityService.shouldShowApiKeyManagement(userProfile: viewState.userProfile)
    }
    
    // MARK: - Sign Out Handler
    
    private func handleSignOut() {
        utilityService.handleSignOut(viewState: viewState, appCoordinator: appCoordinator)
    }
    
    // MARK: - Data Export Handler
    
    private func handleDataExport() async {
        guard let userId = appCoordinator.currentUserId,
              let userEmail = viewState.userProfile?.email else {
            print("❌ No user ID or email available for data export")
            return
        }
        
        await dataService.handleDataExport(userId: userId, userEmail: userEmail, viewState: viewState)
    }
    
    // MARK: - Account Deletion Handler
    
    private func handleAccountDeletion() async {
        guard let userId = appCoordinator.currentUserId else {
            print("❌ No user ID available for account deletion")
            return
        }
        
        await dataService.handleAccountDeletion(userId: userId, viewState: viewState, appCoordinator: appCoordinator)
    }
    
    // MARK: - Family Language Data Loading
    
    private func loadFamilyLanguageData() async {
        guard let familyId = appCoordinator.currentFamilyId else {
            print("❌ No family ID available for language data loading")
            return
        }
        
        await accountService.loadFamilyLanguageData(familyId: familyId, viewState: viewState)
    }
    
    // MARK: - Feature Flag State Loading
    
    private func loadFeatureFlagStates() async {
        await accountService.loadFeatureFlagStates(viewState: viewState)
    }
    
    private func updateTranslationStrategy(_ strategy: TranslationGenerationStrategy) async {
        guard let familyId = appCoordinator.currentFamilyId else {
            print("❌ No family ID available for strategy update")
            return
        }
        
        await accountService.updateTranslationStrategy(strategy, familyId: familyId, viewState: viewState)
    }

    // MARK: - Support Email Handler (delegated to service)
    
    private func openSupportEmail() {
        utilityService.openSupportEmail(appCoordinator: appCoordinator, viewState: viewState)
    }
    
    // MARK: - App Info Helpers (delegated to service)
    
    private func getAppVersion() -> String {
        utilityService.getAppVersion()
    }
    
    private func getBuildNumber() -> String {
        utilityService.getBuildNumber()
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
    
    // MARK: - Account Data Loading (delegated to service)
    
    private func loadUserProfile() async {
        guard let userId = appCoordinator.currentUserId else {
            print("❌ No current user ID available for loading profile")
            return
        }
        
        await accountService.loadUserProfile(userId: userId, viewState: viewState)
    }
    
    // MARK: - Language Selection Handler (delegated to service)
    
    private func handleLanguageUpdate(_ newLanguage: String) async {
        guard let userId = appCoordinator.currentUserId else {
            return
        }
        
        await accountService.handleLanguageUpdate(newLanguage, userId: userId, viewState: viewState)
    }
    
    // MARK: - Child Profile Save Handler (delegated to service)
    
    private func handleChildSave(childId: String, name: String, age: Int?, pronouns: String?) async -> Bool {
        return await accountService.handleChildSave(childId: childId, name: name, age: age, pronouns: pronouns, appCoordinator: appCoordinator)
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
                FoundationToolsSection(
                    frameworkState: frameworkState,
                    viewState: viewState,
                    onLoadUserProfile: loadUserProfile,
                    onLoadFamilyLanguageData: loadFamilyLanguageData,
                    onLoadFeatureFlagStates: loadFeatureFlagStates
                )
                
                // Guidance Structure Section
                GuidanceStructureSection(
                    guidanceStructureSettings: guidanceStructureSettings,
                    viewState: viewState
                )
                
                // Child Profile Section
                ChildProfileSection(
                    viewState: viewState,
                    formatChildAge: formatChildAge
                )
                
                // Account Section
                AccountSection(
                    viewState: viewState,
                    formatEmailText: formatEmailText,
                    formatPlanText: formatPlanText,
                    formatApiKeyStatus: formatApiKeyStatus,
                    formatLanguageText: formatLanguageText,
                    shouldShowApiKeyManagement: shouldShowApiKeyManagement
                )
                
                // Family Language Section
                FamilyLanguageSection(viewState: viewState)
                
                // Developer Section (for testing EdgeFunction migration)
                DeveloperSection(viewState: viewState)
                
                // Privacy & Data Section
                PrivacyDataSection(
                    viewState: viewState,
                    onDataExport: handleDataExport
                )
                
                // Help & Support Section
                HelpSupportSection(
                    viewState: viewState,
                    openSupportEmail: openSupportEmail,
                    getAppVersion: getAppVersion,
                    getBuildNumber: getBuildNumber,
                    debugInfoSection: AnyView(debugInfoSection)
                )
            }
            .padding(.top, 16)
            .padding(.bottom, 100) // Space for tab bar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .overlay(frameworkRemovalConfirmationOverlay)
        .overlay(
            SignOutConfirmationView(
                viewState: viewState,
                handleSignOut: handleSignOut
            )
        )
        .overlay(deleteAccountConfirmationOverlay)
        .sheet(isPresented: $viewState.showingChildEdit) {
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
        .sheet(isPresented: $viewState.showingApiKeyManagement) {
            if let profile = viewState.userProfile {
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
                                viewState.showingApiKeyManagement = false
                            }
                            .foregroundColor(ColorPalette.white)
                        }
                    }
                }
            }
        }
        .alert(String(localized: "settings.export.alert.title"), isPresented: $viewState.showingExportSuccess) {
            Button(String(localized: "common.ok")) {
                viewState.showingExportSuccess = false
                viewState.exportSuccessMessage = nil
            }
        } message: {
            Text(viewState.exportSuccessMessage ?? "")
        }
        .sheet(isPresented: $viewState.showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $viewState.showingDocumentation) {
            DocumentationView()
        }
        .sheet(isPresented: $viewState.showingLanguageSelection) {
            LanguageSelectionView(
                selectedLanguage: $viewState.selectedLanguage,
                onLanguageSelected: { language in
                    Task {
                        await handleLanguageUpdate(language)
                    }
                    viewState.showingLanguageSelection = false
                }
            )
        }
        .sheet(isPresented: $viewState.showingStrategySelection) {
            TranslationStrategySelectionView(
                currentStrategy: viewState.currentTranslationStrategy,
                familyUsageMetrics: viewState.familyUsageMetrics,
                onStrategySelected: { strategy in
                    Task {
                        await updateTranslationStrategy(strategy)
                    }
                }
            )
        }
    }
    
    // MARK: - Section Views
    
    
    
    
    
    


    
    
    
    // MARK: - Delete Account Confirmation
    
    private var deleteAccountConfirmationOverlay: some View {
        Group {
            if viewState.showingDeleteConfirmation {
                ZStack {
                    // Semi-transparent background
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            viewState.showingDeleteConfirmation = false
                            viewState.deleteConfirmationStep = 0
                        }
                    
                    // Multi-step confirmation dialog
                    DeleteAccountConfirmationView(
                        step: viewState.deleteConfirmationStep,
                        isDeleting: viewState.isDeletingAccount,
                        onNextStep: {
                            viewState.deleteConfirmationStep += 1
                        },
                        onDelete: {
                            Task {
                                await handleAccountDeletion()
                            }
                        },
                        onCancel: {
                            viewState.showingDeleteConfirmation = false
                            viewState.deleteConfirmationStep = 0
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
                        title: String(localized: "framework.remove.title"),
                        message: String(localized: "framework.remove.message"),
                        destructiveButtonTitle: frameworkState.isRemoving ? String(localized: "framework.remove.progress") : String(localized: "framework.action.remove"),
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

// MARK: - Framework Card Component


// MARK: - Privacy Policy View

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
                        title: String(localized: "documentation.section.gettingStarted"),
                        items: [
                            ("How do I add my child's information?", "Go to Settings > Child Profile and tap 'Edit Profile' to update your child's name and date of birth."),
                            ("How do I get parenting guidance?", "Tap the 'New' tab and describe a parenting situation. The AI will provide personalized guidance based on your input."),
                            ("What are Foundation Tools?", "Foundation Tools are evidence-based parenting frameworks recommended by our AI based on your situations and needs.")
                        ]
                    )
                    
                    faqSection(
                        title: String(localized: "documentation.section.usingApp"),
                        items: [
                            ("How do I save a situation for later?", "Tap the heart icon on any situation in your Library to mark it as a favorite for easy access."),
                            ("Can I export my data?", "Yes! Go to Settings > Privacy & Data > 'Export My Data' to receive all your information via email."),
                            ("How do I set up a parenting framework?", "Select multiple related situations in your Library and tap 'Set Up Framework' to get AI-generated framework recommendations.")
                        ]
                    )
                    
                    faqSection(
                        title: String(localized: "documentation.section.accountApi"),
                        items: [
                            ("What's the difference between plans?", "Subscription plans include AI processing, while 'Bring Your Own API' lets you use your personal OpenAI API key."),
                            ("How do I add my OpenAI API key?", "If you selected 'Bring Your Own API', go to Settings > Account > 'Manage API Key' to add your key."),
                            ("Is my data secure?", "Yes, all data is encrypted and securely stored. You can export or delete your data anytime in Settings.")
                        ]
                    )
                    
                    faqSection(
                        title: String(localized: "documentation.section.troubleshooting"),
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
                    Button(String(localized: "common.button.done")) {
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

// MARK: - Language Selection View



#Preview {
    SettingsView()
}
