//
//  ChildProfileSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct ChildProfileSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var appCoordinator: AppCoordinator
    @ObservedObject var viewState: SettingsViewState
    
    let formatChildAge: (Child?) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "settings.childProfile.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(SemanticColors.primaryText)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(String(localized: "settings.childProfile.name"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Spacer()
                    
                    Text(appCoordinator.children.first?.name ?? "Not set")
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                }
                
                HStack {
                    Text(String(localized: "settings.childProfile.age"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Spacer()
                    
                    Text(formatChildAge(appCoordinator.children.first))
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                }
                
                Button(String(localized: "settings.childProfile.editProfile")) {
                    if appCoordinator.children.first != nil {
                        viewState.showingChildEdit = true
                    }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.accent)
            }
            .padding(16)
            .background(SemanticColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: colorScheme == .light ? Color.black.opacity(0.1) : Color.clear, radius: 2, x: 0, y: 1)
            .padding(.horizontal, 16)
        }
    }
}
