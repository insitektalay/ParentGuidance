//
//  JoinFamilyView.swift
//  ParentGuidance
//
//  Created by alex kerss on 19/07/2025.
//

import SwiftUI

struct JoinFamilyView: View {
    let onSuccessfulJoin: (String) -> Void
    let onBackTapped: () -> Void
    
    @State private var invitationCode: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var invitationInfo: FamilyInvitationInfo? = nil
    @State private var isValidating: Bool = false
    
    @FocusState private var isCodeFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Text(String(localized: "onboarding.joinFamily.title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(ColorPalette.navy)
                    .multilineTextAlignment(.center)
                
                Text(String(localized: "onboarding.joinFamily.subtitle"))
                    .font(.body)
                    .foregroundColor(ColorPalette.navy)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 60)
            .padding(.bottom, 40)
            
            Spacer()
            
            // Main Content
            VStack(spacing: 24) {
                // Invitation Code Input
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "onboarding.joinFamily.codeLabel"))
                            .font(.headline)
                            .foregroundColor(ColorPalette.navy)
                        
                        TextField(String(localized: "onboarding.joinFamily.codePlaceholder"), text: $invitationCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 17, design: .monospaced))
                            .textCase(.uppercase)
                            .autocorrectionDisabled()
                            .focused($isCodeFieldFocused)
                            .onChange(of: invitationCode) { oldValue, newValue in
                                // Format as uppercase and limit to 8 characters
                                let filtered = String(newValue.uppercased().prefix(8))
                                if filtered != newValue {
                                    invitationCode = filtered
                                }
                                
                                // Clear previous validation state when user types
                                if invitationInfo != nil {
                                    invitationInfo = nil
                                }
                                if errorMessage != nil {
                                    errorMessage = nil
                                }
                                
                                // Auto-validate when 8 characters entered
                                if filtered.count == 8 && !isValidating {
                                    Task {
                                        await validateInvitationCode()
                                    }
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        errorMessage != nil ? Color.red :
                                        invitationInfo != nil ? Color.green :
                                        Color.clear,
                                        lineWidth: 2
                                    )
                            )
                    }
                    
                    // Helper Text
                    Text(String(localized: "onboarding.joinFamily.codeHelper"))
                        .font(.caption)
                        .foregroundColor(ColorPalette.navy)
                        .multilineTextAlignment(.center)
                }
                
                // Validation State
                Group {
                    if isValidating {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(String(localized: "onboarding.joinFamily.validating"))
                                .font(.body)
                                .foregroundColor(ColorPalette.navy)
                        }
                        .padding()
                    } else if let error = errorMessage {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.body)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    } else if let info = invitationInfo {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(String(localized: "onboarding.joinFamily.validCode"))
                                    .font(.body)
                                    .foregroundColor(.green)
                            }
                            
                            VStack(spacing: 8) {
                                Text(String(localized: "onboarding.joinFamily.invitedBy"))
                                    .font(.caption)
                                    .foregroundColor(ColorPalette.navy)
                                Text(info.inviterName)
                                    .font(.headline)
                                    .foregroundColor(ColorPalette.navy)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Join Button
                Button(action: {
                    Task {
                        await joinFamily()
                    }
                }) {
                    Group {
                        if isLoading {
                            HStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text(String(localized: "onboarding.joinFamily.joining"))
                            }
                        } else {
                            Text(String(localized: "onboarding.joinFamily.joinButton"))
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        invitationInfo != nil && !isLoading ?
                        ColorPalette.terracotta :
                        ColorPalette.terracotta.opacity(0.5)
                    )
                    .cornerRadius(12)
                }
                .disabled(invitationInfo == nil || isLoading)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Back Button
            HStack {
                Button(action: onBackTapped) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text(String(localized: "onboarding.button.back"))
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(ColorPalette.navy)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(ColorPalette.cream)
        .ignoresSafeArea()
        .onAppear {
            isCodeFieldFocused = true
        }
    }
    
    private func validateInvitationCode() async {
        guard !invitationCode.isEmpty else { return }
        
        isValidating = true
        errorMessage = nil
        
        do {
            let info = try await FamilyInvitationService.shared.validateInvitation(code: invitationCode)
            await MainActor.run {
                invitationInfo = info
                isValidating = false
            }
        } catch {
            await MainActor.run {
                invitationInfo = nil
                errorMessage = error.localizedDescription
                isValidating = false
            }
        }
    }
    
    private func joinFamily() async {
        guard let invitationInfo = invitationInfo else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Get current user ID from Supabase auth
            guard let userId = SupabaseManager.shared.client.auth.currentUser?.id.uuidString else {
                errorMessage = String(localized: "onboarding.joinFamily.error.notAuthenticated")
                isLoading = false
                return
            }
            
            let familyId = try await FamilyInvitationService.shared.useInvitation(
                code: invitationCode,
                userId: userId
            )
            
            await MainActor.run {
                isLoading = false
                onSuccessfulJoin(familyId)
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    JoinFamilyView(
        onSuccessfulJoin: { _ in },
        onBackTapped: {}
    )
}
