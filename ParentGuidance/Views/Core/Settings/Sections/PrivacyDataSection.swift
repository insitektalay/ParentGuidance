//
//  PrivacyDataSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct PrivacyDataSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewState: SettingsViewState
    
    let onDataExport: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "settings.privacyData.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(SemanticColors.primaryText)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                Button(viewState.isExportingData ? String(localized: "settings.export.progress") : String(localized: "settings.export.button")) {
                    Task {
                        await onDataExport()
                    }
                }
                .disabled(viewState.isExportingData)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(String(localized: "settings.privacyData.privacyPolicy")) {
                    viewState.showingPrivacyPolicy = true
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(String(localized: "settings.account.deleteAccount")) {
                    viewState.deleteConfirmationStep = 0
                    viewState.showingDeleteConfirmation = true
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SemanticColors.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(SemanticColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: colorScheme == .light ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
            .padding(.horizontal, 16)
        }
    }
}