//
//  HelpSupportSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct HelpSupportSection: View {
    @ObservedObject var viewState: SettingsViewState
    
    let openSupportEmail: () -> Void
    let getAppVersion: () -> String
    let getBuildNumber: () -> String
    let debugInfoSection: AnyView
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "settings.helpSupport.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                Button(String(localized: "settings.helpSupport.documentation")) {
                    viewState.showingDocumentation = true
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
                        viewState.showDebugInfo.toggle()
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
                    
                    if viewState.showDebugInfo {
                        debugInfoSection
                            .animation(.easeInOut(duration: 0.2), value: viewState.showDebugInfo)
                    }
                }
            }
            .padding(16)
            .background(ColorPalette.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }
}
