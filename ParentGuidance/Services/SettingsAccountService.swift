//
//  SettingsAccountService.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import Foundation
import SwiftUI
import Supabase

/// Service responsible for handling account-related operations including profile loading, language management, and child profile updates
class SettingsAccountService: ObservableObject {
    static let shared = SettingsAccountService()
    
    private init() {}
    
    // MARK: - Profile Loading
    
    func loadUserProfile(userId: String, viewState: SettingsViewState) async {
        await MainActor.run {
            viewState.isLoadingProfile = true
        }
        
        do {
            let profile = try await AuthService.shared.loadUserProfile(userId: userId)
            await MainActor.run {
                viewState.userProfile = profile
                viewState.selectedLanguage = profile.preferredLanguage
                viewState.isLoadingProfile = false
            }
            print("✅ Settings: User profile loaded successfully")
        } catch {
            print("❌ Settings: Failed to load user profile: \(error.localizedDescription)")
            await MainActor.run {
                viewState.isLoadingProfile = false
            }
        }
    }
    
    // MARK: - Family Language Data
    
    func loadFamilyLanguageData(familyId: String, viewState: SettingsViewState) async {
        await MainActor.run {
            viewState.isLoadingFamilyLanguage = true
        }
        
        do {
            // Load family language configuration
            let config = try await FamilyLanguageService.shared.getFamilyLanguageConfiguration(familyId: familyId)
            
            // Load current translation strategy
            let strategy = try await FamilyLanguageService.shared.getTranslationStrategy(for: familyId)
            
            // Load usage metrics if available
            let metrics = TranslationQueueManager.shared.getFamilyUsageMetrics(familyId: familyId)
            
            await MainActor.run {
                viewState.familyLanguageConfig = config
                viewState.currentTranslationStrategy = strategy
                viewState.familyUsageMetrics = metrics.totalContentAccesses > 0 ? metrics : nil
                viewState.isLoadingFamilyLanguage = false
            }
            
            print("✅ Family language data loaded successfully")
            
        } catch {
            await MainActor.run {
                viewState.isLoadingFamilyLanguage = false
            }
            print("❌ Error loading family language data: \(error)")
        }
    }
    
    // MARK: - Feature Flag States
    
    func loadFeatureFlagStates(viewState: SettingsViewState) async {
        await MainActor.run {
            // Load current feature flag states from UserDefaults
            viewState.translationUseEdgeFunction = TranslationService.isUsingEdgeFunction()
            viewState.conversationUseEdgeFunction = ConversationService.isUsingEdgeFunction()
            viewState.frameworkUseEdgeFunction = FrameworkGenerationService.isUsingEdgeFunction()
            viewState.contextUseEdgeFunction = ContextualInsightService.isUsingEdgeFunction()
            viewState.guidanceUseEdgeFunction = GuidanceGenerationService.isUsingEdgeFunction()
            
            print("🔧 Feature flag states loaded:")
            print("   Translation: \(viewState.translationUseEdgeFunction ? "Edge Function" : "Direct API")")
            print("   Conversation: \(viewState.conversationUseEdgeFunction ? "Edge Function" : "Direct API")")
            print("   Framework: \(viewState.frameworkUseEdgeFunction ? "Edge Function" : "Direct API")")
            print("   Context: \(viewState.contextUseEdgeFunction ? "Edge Function" : "Direct API")")
            print("   Guidance: \(viewState.guidanceUseEdgeFunction ? "Edge Function" : "Direct API")")
        }
    }
    
    // MARK: - Translation Strategy
    
    func updateTranslationStrategy(_ strategy: TranslationGenerationStrategy, familyId: String, viewState: SettingsViewState) async {
        do {
            try await FamilyLanguageService.shared.setTranslationStrategy(strategy, for: familyId)
            
            await MainActor.run {
                viewState.currentTranslationStrategy = strategy
                viewState.showingStrategySelection = false
            }
            
            print("✅ Translation strategy updated to: \(strategy.rawValue)")
            
        } catch {
            print("❌ Error updating translation strategy: \(error)")
        }
    }
    
    // MARK: - Language Update
    
    func handleLanguageUpdate(_ newLanguage: String, userId: String, viewState: SettingsViewState) async {
        guard newLanguage != viewState.userProfile?.preferredLanguage else {
            return
        }
        
        do {
            // Update language preference in database
            try await SupabaseManager.shared.client
                .from("profiles")
                .update(["preferred_language": newLanguage])
                .eq("id", value: userId)
                .execute()
            
            // Update local state
            await MainActor.run {
                viewState.selectedLanguage = newLanguage
            }
            
            // Reload the user profile to get the updated data
            await loadUserProfile(userId: userId, viewState: viewState)
            
            print("✅ Language preference updated to: \(newLanguage)")
            
        } catch {
            print("❌ Failed to update language preference: \(error)")
        }
    }
    
    // MARK: - Child Profile
    
    func handleChildSave(childId: String, name: String, age: Int?, pronouns: String?, appCoordinator: AppCoordinator) async -> Bool {
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
}
