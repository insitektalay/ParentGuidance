//
//  FamilyInvitationService.swift
//  ParentGuidance
//
//  Created by alex kerss on 19/07/2025.
//

import Foundation
import Supabase

/// Service for managing family invitations and joining existing families
class FamilyInvitationService {
    static let shared = FamilyInvitationService()
    
    private init() {}
    
    // MARK: - Invitation Creation
    
    /// Generate a new invitation code for an existing family
    func createInvitation(familyId: String, invitedBy: String) async throws -> String {
        print("🔗 Creating family invitation for family: \(familyId)")
        
        let invitationCode = generateInvitationCode()
        let expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date().addingTimeInterval(7 * 24 * 60 * 60)
        
        let invitation: [String: String] = [
            "family_id": familyId,
            "invited_by": invitedBy,
            "invitation_code": invitationCode,
            "expires_at": ISO8601DateFormatter().string(from: expiresAt),
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            try await SupabaseManager.shared.client
                .from("family_invitations")
                .insert(invitation)
                .execute()
            
            print("✅ Family invitation created with code: \(invitationCode)")
            return invitationCode
            
        } catch {
            print("❌ Failed to create family invitation: \(error)")
            throw FamilyInvitationError.creationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Invitation Validation
    
    /// Validate an invitation code and return family information
    func validateInvitation(code: String) async throws -> FamilyInvitationInfo {
        print("🔍 Validating invitation code: \(code)")
        
        guard !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FamilyInvitationError.invalidCode
        }
        
        do {
            // Get invitation with family and inviter information
            let response: [FamilyInvitationRecord] = try await SupabaseManager.shared.client
                .from("family_invitations")
                .select("""
                    id,
                    family_id,
                    invited_by,
                    invitation_code,
                    expires_at,
                    used_at,
                    profiles!invited_by (
                        email,
                        full_name
                    )
                """)
                .eq("invitation_code", value: code.uppercased())
                .execute()
                .value
            
            guard let invitation = response.first else {
                print("❌ Invitation code not found: \(code)")
                throw FamilyInvitationError.invalidCode
            }
            
            // Check if invitation has been used
            if invitation.usedAt != nil {
                print("❌ Invitation code already used: \(code)")
                throw FamilyInvitationError.alreadyUsed
            }
            
            // Check if invitation has expired
            let formatter = ISO8601DateFormatter()
            if let expiryDate = formatter.date(from: invitation.expiresAt),
               expiryDate < Date() {
                print("❌ Invitation code expired: \(code)")
                throw FamilyInvitationError.expired
            }
            
            print("✅ Invitation code validated successfully")
            return FamilyInvitationInfo(
                familyId: invitation.familyId,
                inviterName: invitation.inviterProfile?.fullName ?? invitation.inviterProfile?.email ?? "Family Member",
                inviterEmail: invitation.inviterProfile?.email
            )
            
        } catch {
            if error is FamilyInvitationError {
                throw error
            }
            print("❌ Error validating invitation: \(error)")
            throw FamilyInvitationError.validationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Invitation Usage
    
    /// Use an invitation code to join a family
    func useInvitation(code: String, userId: String) async throws -> String {
        print("🏠 Using invitation code to join family: \(code)")
        
        // First validate the invitation
        let invitationInfo = try await validateInvitation(code: code)
        
        do {
            // Mark invitation as used
            try await SupabaseManager.shared.client
                .from("family_invitations")
                .update([
                    "used_at": ISO8601DateFormatter().string(from: Date()),
                    "used_by": userId
                ])
                .eq("invitation_code", value: code.uppercased())
                .execute()
            
            // Update user's profile to join the family
            try await SupabaseManager.shared.client
                .from("profiles")
                .update(["family_id": invitationInfo.familyId])
                .eq("id", value: userId)
                .execute()
            
            print("✅ Successfully joined family: \(invitationInfo.familyId)")
            return invitationInfo.familyId
            
        } catch {
            print("❌ Failed to use invitation: \(error)")
            throw FamilyInvitationError.usageFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Invitation Management
    
    /// Get all active invitations for a family
    func getActiveInvitations(familyId: String) async throws -> [FamilyInvitationRecord] {
        print("📋 Getting active invitations for family: \(familyId)")
        
        do {
            let response: [FamilyInvitationRecord] = try await SupabaseManager.shared.client
                .from("family_invitations")
                .select("*")
                .eq("family_id", value: familyId)
                .is("used_at", value: nil)
                .gt("expires_at", value: ISO8601DateFormatter().string(from: Date()))
                .execute()
                .value
            
            print("✅ Found \(response.count) active invitations")
            return response
            
        } catch {
            print("❌ Error getting active invitations: \(error)")
            throw FamilyInvitationError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Revoke (expire) an invitation
    func revokeInvitation(invitationId: String) async throws {
        print("🗑️ Revoking invitation: \(invitationId)")
        
        do {
            try await SupabaseManager.shared.client
                .from("family_invitations")
                .update(["expires_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: invitationId)
                .execute()
            
            print("✅ Invitation revoked successfully")
            
        } catch {
            print("❌ Failed to revoke invitation: \(error)")
            throw FamilyInvitationError.revocationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Generate a random 8-character invitation code
    private func generateInvitationCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
}

// MARK: - Supporting Models

/// Information about a validated family invitation
struct FamilyInvitationInfo {
    let familyId: String
    let inviterName: String
    let inviterEmail: String?
}

/// Database record structure for family invitations
struct FamilyInvitationRecord: Codable {
    let id: String
    let familyId: String
    let invitedBy: String
    let invitationCode: String
    let expiresAt: String
    let usedAt: String?
    let usedBy: String?
    let createdAt: String
    let inviterProfile: InviterProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case invitedBy = "invited_by"
        case invitationCode = "invitation_code"
        case expiresAt = "expires_at"
        case usedAt = "used_at"
        case usedBy = "used_by"
        case createdAt = "created_at"
        case inviterProfile = "profiles"
    }
}

/// Profile information for the user who created the invitation
struct InviterProfile: Codable {
    let email: String?
    let fullName: String?
    
    enum CodingKeys: String, CodingKey {
        case email
        case fullName = "full_name"
    }
}

/// Errors that can occur during family invitation operations
enum FamilyInvitationError: LocalizedError {
    case invalidCode
    case alreadyUsed
    case expired
    case creationFailed(String)
    case validationFailed(String)
    case usageFailed(String)
    case fetchFailed(String)
    case revocationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "Invalid invitation code"
        case .alreadyUsed:
            return "This invitation has already been used"
        case .expired:
            return "This invitation has expired"
        case .creationFailed(let message):
            return "Failed to create invitation: \(message)"
        case .validationFailed(let message):
            return "Failed to validate invitation: \(message)"
        case .usageFailed(let message):
            return "Failed to join family: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch invitations: \(message)"
        case .revocationFailed(let message):
            return "Failed to revoke invitation: \(message)"
        }
    }
}