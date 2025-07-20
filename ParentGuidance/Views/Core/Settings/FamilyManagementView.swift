//
//  FamilyManagementView.swift
//  ParentGuidance
//
//  Created by alex kerss on 19/07/2025.
//

import SwiftUI

struct FamilyManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var familyMembers: [FamilyMember] = []
    @State private var pendingInvitations: [FamilyInvitation] = []
    @State private var familySettings: FamilySettings?
    @State private var isLoading = true
    @State private var showingInviteFlow = false
    @State private var showingMemberEdit: FamilyMember?
    @State private var showingStrategySelection = false
    @State private var errorMessage: String?
    
    private let familyId: String
    
    init(familyId: String) {
        self.familyId = familyId
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else {
                        // Family Overview Header
                        familyOverviewCard
                        
                        // Family Members Section
                        familyMembersSection
                        
                        // Pending Invitations Section
                        if !pendingInvitations.isEmpty {
                            pendingInvitationsSection
                        }
                        
                        // Family Settings Section
                        familySettingsSection
                        
                        // Actions Section
                        familyActionsSection
                    }
                }
                .padding(24)
                .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
            .navigationTitle(String(localized: "settings.familyManagement.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common.back")) {
                        dismiss()
                    }
                    .foregroundColor(ColorPalette.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "settings.familyManagement.inviteFamily")) {
                        showingInviteFlow = true
                    }
                    .foregroundColor(ColorPalette.brightBlue)
                }
            }
        }
        .sheet(isPresented: $showingInviteFlow) {
            // Family invitation flow
            FamilyInviteView(familyId: familyId) { success in
                if success {
                    loadFamilyData()
                }
                showingInviteFlow = false
            }
        }
        .sheet(item: $showingMemberEdit) { member in
            // Member language preference editing
            FamilyMemberEditView(member: member, familyId: familyId) { updatedMember in
                if let index = familyMembers.firstIndex(where: { $0.id == updatedMember.id }) {
                    familyMembers[index] = updatedMember
                }
                showingMemberEdit = nil
            }
        }
        .sheet(isPresented: $showingStrategySelection) {
            if let settings = familySettings {
                TranslationStrategySelectionView(
                    currentStrategy: settings.translationStrategy,
                    familyUsageMetrics: TranslationQueueManager.shared.getFamilyUsageMetrics(familyId: familyId),
                    onStrategySelected: { strategy in
                        updateFamilyTranslationStrategy(strategy)
                        showingStrategySelection = false
                    }
                )
            }
        }
        .task {
            await loadFamilyData()
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .tint(ColorPalette.terracotta)
            Text(String(localized: "settings.familyManagement.loading"))
                .font(.system(size: 16))
                .foregroundColor(ColorPalette.white.opacity(0.7))
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text(String(localized: "settings.familyManagement.error.title"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.top, 8)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
            
            Button(String(localized: "common.tryAgain")) {
                Task { await loadFamilyData() }
            }
            .foregroundColor(ColorPalette.brightBlue)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var familyOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "house.fill")
                    .font(.system(size: 18))
                    .foregroundColor(ColorPalette.terracotta)
                
                Text(String(localized: "settings.familyManagement.overview.title"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ColorPalette.white)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(localized: "settings.familyManagement.overview.members"))
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(familyMembers.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                }
                
                HStack {
                    Text(String(localized: "settings.familyManagement.overview.languages"))
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(getActiveLanguagesText())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                }
                
                if let settings = familySettings {
                    HStack {
                        Text(String(localized: "settings.familyManagement.overview.strategy"))
                            .font(.system(size: 14))
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text(settings.translationStrategy.description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ColorPalette.brightBlue)
                    }
                }
                
                if !pendingInvitations.isEmpty {
                    HStack {
                        Text(String(localized: "settings.familyManagement.overview.pendingInvites"))
                            .font(.system(size: 14))
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text("\(pendingInvitations.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.21, green: 0.22, blue: 0.33))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var familyMembersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(String(localized: "settings.familyManagement.members.title"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ColorPalette.white)
                
                Spacer()
                
                Button(String(localized: "settings.familyManagement.members.addMember")) {
                    showingInviteFlow = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorPalette.brightBlue)
            }
            
            VStack(spacing: 12) {
                ForEach(familyMembers) { member in
                    FamilyMemberCard(
                        member: member,
                        onEdit: {
                            showingMemberEdit = member
                        },
                        onRemove: {
                            removeFamilyMember(member)
                        }
                    )
                }
            }
        }
    }
    
    private var pendingInvitationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "settings.familyManagement.invitations.title"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ColorPalette.white)
            
            VStack(spacing: 12) {
                ForEach(pendingInvitations) { invitation in
                    PendingInvitationCard(
                        invitation: invitation,
                        onResend: {
                            resendInvitation(invitation)
                        },
                        onCancel: {
                            cancelInvitation(invitation)
                        }
                    )
                }
            }
        }
    }
    
    private var familySettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "settings.familyManagement.settings.title"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ColorPalette.white)
            
            VStack(spacing: 12) {
                // Translation Strategy Setting
                Button(action: {
                    showingStrategySelection = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "settings.familyManagement.settings.translationStrategy"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(ColorPalette.white)
                            
                            if let settings = familySettings {
                                Text(settings.translationStrategy.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(ColorPalette.white.opacity(0.7))
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                    }
                    .padding(16)
                    .background(Color(red: 0.21, green: 0.22, blue: 0.33))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Family Language Coordination
                familyLanguageCoordinationCard
                
                // Usage Analytics
                familyUsageAnalyticsCard
            }
        }
    }
    
    private var familyLanguageCoordinationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "settings.familyManagement.settings.languageCoordination"))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(getLanguageBreakdown(), id: \.language) { item in
                    HStack {
                        Text(item.language)
                            .font(.system(size: 14))
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text(String(localized: "settings.familyManagement.settings.membersCount", defaultValue: "\(item.memberCount) members"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ColorPalette.white)
                        
                        if item.isConflict {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            if hasLanguageConflicts() {
                Text(String(localized: "settings.familyManagement.settings.languageConflictWarning"))
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(red: 0.21, green: 0.22, blue: 0.33))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var familyUsageAnalyticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "settings.familyManagement.settings.usageAnalytics"))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white)
            
            let metrics = TranslationQueueManager.shared.getFamilyUsageMetrics(familyId: familyId)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(localized: "settings.familyManagement.analytics.totalContent"))
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(metrics.uniqueContentAccessed)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                }
                
                HStack {
                    Text(String(localized: "settings.familyManagement.analytics.avgAccess"))
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(String(format: "%.1f", metrics.averageAccessesPerContent))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                }
                
                HStack {
                    Text(String(localized: "settings.familyManagement.analytics.familyType"))
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(metrics.isHighUsageFamily ? "High Usage" : "Low Usage")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(metrics.isHighUsageFamily ? .green : ColorPalette.white)
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.21, green: 0.22, blue: 0.33))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var familyActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "settings.familyManagement.actions.title"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ColorPalette.white)
            
            VStack(spacing: 12) {
                // Export Family Data
                Button(action: {
                    exportFamilyData()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundColor(ColorPalette.brightBlue)
                        
                        Text(String(localized: "settings.familyManagement.actions.exportData"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ColorPalette.white)
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(Color(red: 0.21, green: 0.22, blue: 0.33))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Leave Family (if not admin)
                if !isCurrentUserFamilyAdmin() {
                    Button(action: {
                        leaveFamilyConfirmation()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                            
                            Text(String(localized: "settings.familyManagement.actions.leaveFamily"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(Color(red: 0.21, green: 0.22, blue: 0.33))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getActiveLanguagesText() -> String {
        let languages = Set(familyMembers.compactMap { $0.preferredLanguage })
        return languages.isEmpty ? "English" : Array(languages).joined(separator: ", ")
    }
    
    private func getLanguageBreakdown() -> [LanguageBreakdownItem] {
        let languageGroups = Dictionary(grouping: familyMembers) { $0.preferredLanguage ?? "en" }
        
        return languageGroups.map { language, members in
            let memberCount = members.count
            let isConflict = languageGroups.count > 1 && memberCount < familyMembers.count / 2
            
            return LanguageBreakdownItem(
                language: FamilyLanguageService.shared.getLanguageName(for: language),
                memberCount: memberCount,
                isConflict: isConflict
            )
        }.sorted { $0.memberCount > $1.memberCount }
    }
    
    private func hasLanguageConflicts() -> Bool {
        return getLanguageBreakdown().contains { $0.isConflict }
    }
    
    private func isCurrentUserFamilyAdmin() -> Bool {
        guard let currentUserId = SupabaseManager.shared.client.auth.currentUser?.id.uuidString else {
            return false
        }
        return familyMembers.first { $0.userId == currentUserId }?.role == .admin
    }
    
    // MARK: - Data Loading
    
    private func loadFamilyData() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            async let membersTask = loadFamilyMembers()
            async let invitationsTask = loadPendingInvitations()
            async let settingsTask = loadFamilySettings()
            
            let (members, invitations, settings) = try await (membersTask, invitationsTask, settingsTask)
            
            await MainActor.run {
                self.familyMembers = members
                self.pendingInvitations = invitations
                self.familySettings = settings
                self.isLoading = false
            }
            
        } catch {
            print("❌ Error loading family data: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func loadFamilyMembers() async throws -> [FamilyMember] {
        // This would load from the database
        // For now, return mock data
        return [
            FamilyMember(
                id: "1",
                userId: SupabaseManager.shared.client.auth.currentUser?.id.uuidString ?? "current",
                name: "You",
                email: "user@example.com",
                preferredLanguage: "en",
                role: .admin,
                joinedAt: Date()
            )
        ]
    }
    
    private func loadPendingInvitations() async throws -> [FamilyInvitation] {
        // This would load from the database
        return []
    }
    
    private func loadFamilySettings() async throws -> FamilySettings {
        // This would load from the database
        let strategy = try await FamilyLanguageService.shared.getTranslationStrategy(for: familyId)
        return FamilySettings(
            familyId: familyId,
            translationStrategy: strategy,
            allowMemberInvites: true,
            requireApprovalForNewMembers: false
        )
    }
    
    // MARK: - Actions
    
    private func updateFamilyTranslationStrategy(_ strategy: TranslationGenerationStrategy) {
        Task {
            do {
                // For now, just update the local state since we don't have the database method yet
                await MainActor.run {
                    familySettings?.translationStrategy = strategy
                }
                print("✅ Updated family translation strategy to: \(strategy)")
            } catch {
                print("❌ Error updating translation strategy: \(error)")
            }
        }
    }
    
    private func removeFamilyMember(_ member: FamilyMember) {
        // Implement member removal logic
        print("🗑️ Remove family member: \(member.name)")
    }
    
    private func resendInvitation(_ invitation: FamilyInvitation) {
        // Implement invitation resend logic
        print("📧 Resend invitation to: \(invitation.email)")
    }
    
    private func cancelInvitation(_ invitation: FamilyInvitation) {
        // Implement invitation cancellation logic
        print("❌ Cancel invitation to: \(invitation.email)")
    }
    
    private func exportFamilyData() {
        // Implement family data export
        print("📊 Export family data")
    }
    
    private func leaveFamilyConfirmation() {
        // Implement leave family confirmation dialog
        print("🚪 Leave family confirmation")
    }
    
    // MARK: - Async Support
    
    private func loadFamilyData() {
        Task {
            await loadFamilyData()
        }
    }
}

// MARK: - Supporting Models

struct FamilyMember: Identifiable {
    let id: String
    let userId: String
    let name: String
    let email: String
    let preferredLanguage: String?
    let role: FamilyRole
    let joinedAt: Date
}

struct FamilyInvitation: Identifiable {
    let id: String
    let email: String
    let invitedBy: String
    let sentAt: Date
    let expiresAt: Date
}

struct FamilySettings {
    let familyId: String
    var translationStrategy: TranslationGenerationStrategy
    let allowMemberInvites: Bool
    let requireApprovalForNewMembers: Bool
}

enum FamilyRole: String, CaseIterable {
    case admin = "admin"
    case member = "member"
    
    var displayName: String {
        switch self {
        case .admin:
            return String(localized: "settings.familyManagement.role.admin")
        case .member:
            return String(localized: "settings.familyManagement.role.member")
        }
    }
}

struct LanguageBreakdownItem {
    let language: String
    let memberCount: Int
    let isConflict: Bool
}

// MARK: - Supporting View Components

struct FamilyMemberCard: View {
    let member: FamilyMember
    let onEdit: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(member.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ColorPalette.white)
                        
                        Text(member.role.displayName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(ColorPalette.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(member.role == .admin ? ColorPalette.terracotta : ColorPalette.brightBlue)
                            .cornerRadius(4)
                    }
                    
                    Text(member.email)
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let language = member.preferredLanguage {
                        Text(FamilyLanguageService.shared.getLanguageName(for: language))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ColorPalette.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ColorPalette.brightBlue.opacity(0.6))
                            .cornerRadius(4)
                    }
                    
                    HStack(spacing: 8) {
                        Button(String(localized: "common.edit")) {
                            onEdit()
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ColorPalette.brightBlue)
                        
                        if member.role != .admin {
                            Button(String(localized: "common.remove")) {
                                onRemove()
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.21, green: 0.22, blue: 0.33))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct PendingInvitationCard: View {
    let invitation: FamilyInvitation
    let onResend: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invitation.email)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                    
                    Text("Sent \(invitation.sentAt, format: .relative(presentation: .named))")
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(String(localized: "settings.familyManagement.invitation.resend")) {
                        onResend()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ColorPalette.brightBlue)
                    
                    Button(String(localized: "common.cancel")) {
                        onCancel()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.21, green: 0.22, blue: 0.33).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Placeholder Views (to be implemented separately)

struct FamilyInviteView: View {
    let familyId: String
    let onComplete: (Bool) -> Void
    
    var body: some View {
        Text(String(localized: "familyManagement.inviteView.placeholder"))
            .foregroundColor(ColorPalette.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
    }
}

struct FamilyMemberEditView: View {
    let member: FamilyMember
    let familyId: String
    let onComplete: (FamilyMember) -> Void
    
    var body: some View {
        Text(String(localized: "familyManagement.editView.placeholder"))
            .foregroundColor(ColorPalette.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
    }
}

#Preview {
    FamilyManagementView(familyId: "test-family-id")
}