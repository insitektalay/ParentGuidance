//
//  SettingsViewState.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

// MARK: - Settings View State Management

class SettingsViewState: ObservableObject {
    
    // MARK: - Child Profile Edit State
    
    @Published var showingChildEdit: Bool = false
    
    // MARK: - Account Data State
    
    @Published var userProfile: UserProfile?
    @Published var isLoadingProfile: Bool = false
    @Published var showingApiKeyManagement: Bool = false
    @Published var showingSignOutConfirmation: Bool = false
    @Published var showingLanguageSelection: Bool = false
    @Published var selectedLanguage: String = "en"
    
    // MARK: - Family Language State
    
    @Published var familyLanguageConfig: FamilyLanguageConfiguration?
    @Published var isLoadingFamilyLanguage: Bool = false
    @Published var familyUsageMetrics: TranslationQueueManager.FamilyUsageMetrics?
    @Published var currentTranslationStrategy: TranslationGenerationStrategy = .hybrid
    @Published var showingStrategySelection: Bool = false
    
    // MARK: - EdgeFunction Feature Flag State
    
    @Published var translationUseEdgeFunction: Bool = false
    @Published var conversationUseEdgeFunction: Bool = false
    @Published var frameworkUseEdgeFunction: Bool = false
    @Published var contextUseEdgeFunction: Bool = false
    @Published var guidanceUseEdgeFunction: Bool = false
    
    // MARK: - Privacy & Data State
    
    @Published var isExportingData: Bool = false
    @Published var exportSuccessMessage: String?
    @Published var showingExportSuccess: Bool = false
    @Published var showingDeleteConfirmation: Bool = false
    @Published var deleteConfirmationStep: Int = 0
    @Published var isDeletingAccount: Bool = false
    @Published var showingPrivacyPolicy: Bool = false
    @Published var showingDocumentation: Bool = false
    @Published var showDebugInfo: Bool = false
}
