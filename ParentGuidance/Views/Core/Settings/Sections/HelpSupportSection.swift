//
//  HelpSupportSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct HelpSupportSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewState: SettingsViewState
    
    let openSupportEmail: () -> Void
    let getAppVersion: () -> String
    let getBuildNumber: () -> String
    let debugInfoSection: AnyView
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "settings.helpSupport.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(SemanticColors.primaryText)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                Button(String(localized: "settings.helpSupport.documentation")) {
                    viewState.showingDocumentation = true
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(String(localized: "settings.helpSupport.contactSupport")) {
                    openSupportEmail()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 8) {
                    HStack {
                        Text(String(localized: "settings.helpSupport.appVersion"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SemanticColors.primaryText)
                        
                        Spacer()
                        
                        Text(getAppVersion())
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.secondaryText)
                    }
                    .onTapGesture {
                        viewState.showDebugInfo.toggle()
                    }
                    
                    HStack {
                        Text(String(localized: "settings.helpSupport.build"))
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.secondaryText)
                        
                        Spacer()
                        
                        Text(getBuildNumber())
                            .font(.system(size: 12))
                            .foregroundColor(SemanticColors.tertiaryText)
                    }
                    
                    if viewState.showDebugInfo {
                        debugInfoSection
                            .animation(.easeInOut(duration: 0.2), value: viewState.showDebugInfo)
                    }
                }
            }
            .padding(16)
            .background(SemanticColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: colorScheme == .light ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
            .padding(.horizontal, 16)
        }
    }
}
