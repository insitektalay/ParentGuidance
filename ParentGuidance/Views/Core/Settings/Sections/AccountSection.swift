//
//  AccountSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct AccountSection: View {
    @ObservedObject var viewState: SettingsViewState
    
    let formatEmailText: () -> String
    let formatPlanText: () -> String
    let formatApiKeyStatus: () -> String
    let formatLanguageText: () -> String
    let shouldShowApiKeyManagement: () -> Bool
    
    var body: some View {
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
                
                HStack {
                    Text(String(localized: "settings.account.language"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Button(formatLanguageText()) {
                        viewState.showingLanguageSelection = true
                    }
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.brightBlue)
                }
                
                if shouldShowApiKeyManagement() {
                    Button(String(localized: "settings.account.manageApiKey")) {
                        viewState.showingApiKeyManagement = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorPalette.terracotta)
                }
                
                Button(String(localized: "settings.account.signOut")) {
                    viewState.showingSignOutConfirmation = true
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
}
