//
//  SettingsUtilityService.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import Foundation
import SwiftUI
import UIKit

/// Service responsible for utility functions in settings including email support, app version info, and API key management
class SettingsUtilityService {
    static let shared = SettingsUtilityService()
    
    private init() {}
    
    // MARK: - API Key Management
    
    func shouldShowApiKeyManagement(userProfile: UserProfile?) -> Bool {
        guard let profile = userProfile else { return false }
        return profile.selectedPlan == "api"
    }
    
    // MARK: - Sign Out
    
    func handleSignOut(viewState: SettingsViewState, appCoordinator: AppCoordinator) {
        viewState.showingSignOutConfirmation = false
        appCoordinator.signOut()
    }
    
    // MARK: - Support Email
    
    func openSupportEmail(appCoordinator: AppCoordinator, viewState: SettingsViewState) {
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
                showSupportEmailFallback(viewState: viewState)
            }
        }
    }
    
    private func showSupportEmailFallback(viewState: SettingsViewState) {
        viewState.exportSuccessMessage = "Please email us at support@parentguidance.ai for assistance."
        viewState.showingExportSuccess = true
    }
    
    // MARK: - App Version Info
    
    func getAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    func getBuildNumber() -> String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}
