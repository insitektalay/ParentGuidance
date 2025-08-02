//
//  AccountSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct AccountSection: View {
    @Environment(\.colorScheme) private var colorScheme
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
                .foregroundColor(SemanticColors.primaryText)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(String(localized: "settings.account.email"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Spacer()
                    
                    Text(formatEmailText())
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                }
                
                HStack {
                    Text(String(localized: "settings.account.plan"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Spacer()
                    
                    Text(formatPlanText())
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                }
                
                HStack {
                    Text(String(localized: "settings.account.apiKey"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Spacer()
                    
                    Text(formatApiKeyStatus())
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                }
                
                HStack {
                    Text(String(localized: "settings.account.language"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Spacer()
                    
                    Button(formatLanguageText()) {
                        viewState.showingLanguageSelection = true
                    }
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.accentBlue)
                }
                
                if shouldShowApiKeyManagement() {
                    Button(String(localized: "settings.account.manageApiKey")) {
                        viewState.showingApiKeyManagement = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SemanticColors.accent)
                }
                
                Button(String(localized: "settings.account.signOut")) {
                    viewState.showingSignOutConfirmation = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.accent)
            }
            .padding(16)
            .background(SemanticColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .if(colorScheme == .light) { view in
                view.cardShadow()
            }
            .padding(.horizontal, 16)
        }
    }
}
