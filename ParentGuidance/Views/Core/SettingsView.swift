//
//  SettingsView.swift
//  ParentGuidance
//
//  Created by alex kerss on 20/06/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Settings title
                Text("Settings")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(ColorPalette.white)
                    .padding(.horizontal, 16)
                
                // Foundation Tools Section
                foundationToolsSection
                
                // Child Profile Section
                childProfileSection
                
                // Account Section
                accountSection
                
                // Privacy & Data Section
                privacyDataSection
                
                // Help & Support Section
                helpSupportSection
            }
            .padding(.top, 16)
            .padding(.bottom, 100) // Space for tab bar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
    }
    
    // MARK: - Section Views
    
    private var foundationToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Foundation Tools")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Framework Status")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ColorPalette.white.opacity(0.9))
                
                Text("No active framework currently set up")
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.white.opacity(0.7))
                
                Button("View Framework Tools") {
                    // TODO: Navigate to framework tools
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
    
    private var childProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Child Profile")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Child Name")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text(appCoordinator.children.first?.name ?? "Not set")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                HStack {
                    Text("Age")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text("Not set")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                Button("Edit Profile") {
                    // TODO: Navigate to child profile editing
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
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Email")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text("Loading...")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                HStack {
                    Text("Subscription")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text("Free Plan")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                Button("Sign Out") {
                    // TODO: Handle sign out
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
    
    private var privacyDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy & Data")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                Button("Export My Data") {
                    // TODO: Handle data export
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button("Privacy Policy") {
                    // TODO: Show privacy policy
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button("Delete Account") {
                    // TODO: Handle account deletion
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
    
    private var helpSupportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Help & Support")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                Button("Documentation") {
                    // TODO: Open documentation
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button("Contact Support") {
                    // TODO: Open support contact
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Text("App Version")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                    
                    Text("1.0.0")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
            }
            .padding(16)
            .background(ColorPalette.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    SettingsView()
}
