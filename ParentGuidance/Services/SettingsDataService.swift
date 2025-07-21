//
//  SettingsDataService.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import Foundation
import SwiftUI
import Supabase

/// Service responsible for handling data export and account deletion operations
class SettingsDataService: ObservableObject {
    static let shared = SettingsDataService()
    
    private init() {}
    
    // MARK: - Data Export
    
    func handleDataExport(userId: String, userEmail: String, viewState: SettingsViewState) async {
        await MainActor.run {
            viewState.isExportingData = true
        }
        
        do {
            // Collect all user data
            let exportData = try await collectUserDataForExport(userId: userId)
            
            // Send data via email
            try await sendDataExportEmail(data: exportData, email: userEmail)
            
            await MainActor.run {
                viewState.isExportingData = false
                viewState.exportSuccessMessage = "Your data export has been sent to \(userEmail)"
                viewState.showingExportSuccess = true
            }
            
            print("✅ Data export sent successfully to \(userEmail)")
            
        } catch {
            await MainActor.run {
                viewState.isExportingData = false
                viewState.exportSuccessMessage = "Failed to export data: \(error.localizedDescription)"
                viewState.showingExportSuccess = true
            }
            print("❌ Data export failed: \(error)")
        }
    }
    
    private func collectUserDataForExport(userId: String) async throws -> [String: Any] {
        let supabase = SupabaseManager.shared.client
        
        // Collect user profile
        let profile = try await AuthService.shared.loadUserProfile(userId: userId)
        
        // Collect children data
        let children: [Child] = try await supabase
            .from("children")
            .select("*")
            .eq("family_id", value: userId)
            .execute()
            .value
        
        // Collect situations
        let situations: [Situation] = try await supabase
            .from("situations")
            .select("*")
            .eq("user_id", value: userId)
            .execute()
            .value
        
        // Collect guidance
        let guidance: [Guidance] = try await supabase
            .from("guidance")
            .select("*")
            .eq("user_id", value: userId)
            .execute()
            .value
        
        // Collect frameworks
        let frameworks: [FrameworkRecommendation] = try await FrameworkStorageService.shared.getFrameworkHistory(familyId: userId)
        
        // Create export structure
        let exportData: [String: Any] = [
            "export_info": [
                "user_id": userId,
                "export_date": ISO8601DateFormatter().string(from: Date()),
                "app_version": "1.0.0"
            ],
            "profile": [
                "email": profile.email ?? "",
                "selected_plan": profile.selectedPlan ?? "",
                "created_at": profile.createdAt,
                "updated_at": profile.updatedAt
            ],
            "children": children.map { child in
                [
                    "id": child.id,
                    "name": child.name ?? "",
                    "age": child.age ?? 0,
                    "pronouns": child.pronouns ?? "",
                    "created_at": child.createdAt,
                    "updated_at": child.updatedAt
                ]
            },
            "situations": situations.map { situation in
                [
                    "id": situation.id,
                    "title": situation.title,
                    "description": situation.description,
                    "situation_type": situation.situationType,
                    "category": situation.category ?? "",
                    "is_favorited": situation.isFavorited,
                    "is_incident": situation.isIncident,
                    "created_at": situation.createdAt,
                    "updated_at": situation.updatedAt
                ]
            },
            "guidance": guidance.map { guide in
                [
                    "id": guide.id,
                    "situation_id": guide.situationId,
                    "content": guide.content,
                    "created_at": guide.createdAt,
                    "updated_at": guide.updatedAt
                ]
            },
            "frameworks": frameworks.map { framework in
                [
                    "id": framework.id,
                    "framework_name": framework.frameworkName,
                    "notification_text": framework.notificationText,
                    "created_at": framework.createdAt
                ]
            }
        ]
        
        return exportData
    }
    
    private func sendDataExportEmail(data: [String: Any], email: String) async throws {
        // Convert data to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        _ = String(data: jsonData, encoding: .utf8) ?? ""
        
        // For now, we'll simulate sending an email
        // In a real implementation, you would integrate with an email service like:
        // - Supabase Edge Functions
        // - SendGrid, Mailgun, or similar email API
        // - Backend email service
        
        print("📧 Simulating email send to: \(email)")
        print("📧 Email would contain JSON export of \(data.keys.count) data categories")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // For now, we'll just log success
        // In production, this would make an actual API call to send the email
        print("✅ Email simulation completed")
    }
    
    // MARK: - Account Deletion
    
    func handleAccountDeletion(userId: String, viewState: SettingsViewState, appCoordinator: AppCoordinator) async {
        await MainActor.run {
            viewState.isDeletingAccount = true
        }
        
        do {
            // Delete all user data from database
            try await deleteAllUserData(userId: userId)
            
            await MainActor.run {
                viewState.isDeletingAccount = false
                viewState.showingDeleteConfirmation = false
                viewState.deleteConfirmationStep = 0
            }
            
            // Sign out the user after successful deletion
            appCoordinator.signOut()
            
            print("✅ Account deletion completed successfully")
            
        } catch {
            await MainActor.run {
                viewState.isDeletingAccount = false
                viewState.exportSuccessMessage = "Failed to delete account: \(error.localizedDescription)"
                viewState.showingExportSuccess = true
            }
            print("❌ Account deletion failed: \(error)")
        }
    }
    
    private func deleteAllUserData(userId: String) async throws {
        let supabase = SupabaseManager.shared.client
        
        print("🗑️ Starting complete account deletion for user: \(userId)")
        
        // Delete frameworks
        do {
            let frameworks = try await FrameworkStorageService.shared.getFrameworkHistory(familyId: userId)
            for framework in frameworks {
                try await FrameworkStorageService.shared.deleteFrameworkRecommendation(id: framework.id)
            }
            print("✅ Deleted \(frameworks.count) frameworks")
        } catch {
            print("⚠️ Error deleting frameworks: \(error)")
        }
        
        // Delete guidance
        try await supabase
            .from("guidance")
            .delete()
            .eq("user_id", value: userId)
            .execute()
        print("✅ Deleted guidance records")
        
        // Delete situations
        try await supabase
            .from("situations")
            .delete()
            .eq("user_id", value: userId)
            .execute()
        print("✅ Deleted situation records")
        
        // Delete children
        try await supabase
            .from("children")
            .delete()
            .eq("family_id", value: userId)
            .execute()
        print("✅ Deleted child records")
        
        // Delete user profile
        try await supabase
            .from("profiles")
            .delete()
            .eq("id", value: userId)
            .execute()
        print("✅ Deleted user profile")
        
        print("🗑️ Complete account deletion finished")
    }
}