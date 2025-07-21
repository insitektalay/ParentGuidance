//
//  PrivacyDataSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct PrivacyDataSection: View {
    @ObservedObject var viewState: SettingsViewState
    
    let onDataExport: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "settings.privacyData.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                Button(viewState.isExportingData ? String(localized: "settings.export.progress") : String(localized: "settings.export.button")) {
                    Task {
                        await onDataExport()
                    }
                }
                .disabled(viewState.isExportingData)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(String(localized: "settings.privacyData.privacyPolicy")) {
                    viewState.showingPrivacyPolicy = true
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(String(localized: "settings.account.deleteAccount")) {
                    viewState.deleteConfirmationStep = 0
                    viewState.showingDeleteConfirmation = true
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
}