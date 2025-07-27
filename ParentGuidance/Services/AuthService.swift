//
//  AuthService.swift
//  ParentGuidance
//
//  Created by alex kerss on 06/07/2025.
//

import Foundation
import SwiftUI
import Supabase

// Simplified local OnboardingManager for database operations
class AuthService: ObservableObject {
    static let shared = AuthService()
    private init() {}
    
    func loadUserProfile(userId: String) async throws -> UserProfile {
        let supabase = SupabaseManager.shared.client
        let response: [UserProfile] = try await supabase
            .from("profiles")
            .select("*")
            .eq("id", value: userId)
            .execute()
            .value
        
        guard let profile = response.first else {
            throw NSError(domain: "ProfileNotFound", code: 404)
        }
        
        return profile
    }
    
    func updateSelectedPlan(_ plan: String, userId: String) async throws {
        print("🔄 Attempting to update selected_plan to '\(plan)' for user: \(userId)")
        let supabase = SupabaseManager.shared.client
        
        // First check current user context
        do {
            let currentUser = try await supabase.auth.user()
            print("🔍 Current authenticated user: \(currentUser.id.uuidString)")
            print("🔍 User email: \(currentUser.email ?? "no email")")
            print("🔍 Target user ID: \(userId)")
            print("🔍 User IDs match: \(currentUser.id.uuidString == userId)")
        } catch {
            print("❌ Failed to get current user: \(error)")
        }
        
        // Check if profile exists and is readable
        do {
            let existingProfile: [UserProfile] = try await supabase
                .from("profiles")
                .select("*")
                .eq("id", value: userId)
                .execute()
                .value
            
            if let profile = existingProfile.first {
                print("📊 Found existing profile:")
                print("   - ID: \(profile.id)")
                print("   - Email: \(profile.email ?? "none")")
                print("   - Current plan: \(profile.selectedPlan ?? "none")")
                print("   - Plan setup complete: \(profile.planSetupComplete)")
            } else {
                print("⚠️ No profile found for user \(userId)")
            }
        } catch {
            print("❌ Failed to read existing profile: \(error)")
        }
        
        // Attempt the update
        do {
            let response = try await supabase
                .from("profiles")
                .update([
                    "selected_plan": plan,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: userId)
                .execute()
            
            print("✅ Profile update response: \(response)")
            print("✅ HTTP Status: Success (200)")
            
            // Verify the update actually worked by reading back
            let verifyProfile: [UserProfile] = try await supabase
                .from("profiles")
                .select("*")
                .eq("id", value: userId)
                .execute()
                .value
            
            if let updatedProfile = verifyProfile.first {
                print("✅ Verification - Updated profile:")
                print("   - Selected plan: \(updatedProfile.selectedPlan ?? "none")")
                print("   - Updated at: \(updatedProfile.updatedAt)")
                
                if updatedProfile.selectedPlan == plan {
                    print("✅ Update successful - plan was actually saved!")
                } else {
                    print("❌ Update failed - plan was not saved despite HTTP 200!")
                    print("❌ Expected: \(plan), Got: \(updatedProfile.selectedPlan ?? "none")")
                    throw NSError(domain: "DatabaseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Profile update did not persist"])
                }
            } else {
                print("❌ Verification failed - could not read profile after update")
                throw NSError(domain: "DatabaseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not verify profile update"])
            }
            
        } catch {
            print("❌ Failed to update selected_plan: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    func saveApiKey(_ apiKey: String, provider: ApiKeyProvider = .openai, userId: String) async throws {
        print("🔄 Attempting to save API key for user: \(userId)")
        print("🔑 Provider: \(provider.displayName)")
        print("🔑 API key (first 10 chars): \(apiKey.prefix(10))...")
        
        do {
            // Use the new multi-provider service to add the API key
            let newApiKey = try await MultiProviderApiKeyService.shared.addApiKey(
                userId: userId,
                provider: provider,
                apiKey: apiKey,
                makeActive: true
            )
            
            // Update the profile to mark plan setup as complete
            let supabase = SupabaseManager.shared.client
            let response = try await supabase
                .from("profiles")
                .update([
                    "plan_setup_complete": "true",
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: userId)
                .execute()
            
            print("✅ Profile updated to mark plan setup complete")
            print("✅ API key saved successfully with ID: \(newApiKey.id)")
            
        } catch {
            print("❌ Failed to save API key: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    func saveChildDetails(name: String, birthDate: Date, userId: String) async throws {
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        print("🔄 Attempting to save child details for user: \(userId)")
        print("👶 Child: \(name), age: \(age)")
        print("👶 Family ID will be: \(userId) (using user ID as family ID)")
        let supabase = SupabaseManager.shared.client
        
        // Create the child record first
        print("👶 Creating child record in database...")
        struct ChildInsert: Codable {
            let family_id: String
            let name: String
            let age: Int
            let created_at: String
            let updated_at: String
        }
        
        let childData = ChildInsert(
            family_id: userId,
            name: name,
            age: age,
            created_at: ISO8601DateFormatter().string(from: Date()),
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        do {
            let childResponse = try await supabase
                .from("children")
                .insert(childData)
                .execute()
            
            print("✅ Child record created: \(childResponse)")
            
            // Update profile to mark child details complete
            let profileResponse = try await supabase
                .from("profiles")
                .update([
                    "child_details_complete": "true",
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: userId)
                .execute()
            
            print("✅ Profile updated: \(profileResponse)")
            
            // Verify both the child record and profile update worked
            let childrenResult: [Child] = try await supabase
                .from("children")
                .select("*")
                .eq("family_id", value: userId)
                .execute()
                .value
            
            let profileResult: [UserProfile] = try await supabase
                .from("profiles")
                .select("*")
                .eq("id", value: userId)
                .execute()
                .value
            
            print("✅ Verification Results:")
            print("   - Children found: \(childrenResult.count)")
            if let lastChild = childrenResult.last {
                print("   - Latest child: \(lastChild.name ?? "no name"), age \(lastChild.age)")
            }
            
            if let profile = profileResult.first {
                print("   - Child details complete: \(profile.childDetailsComplete)")
                
                if childrenResult.count > 0 && profile.childDetailsComplete {
                    print("✅ Child details update successful - data was actually saved!")
                } else {
                    print("❌ Child details update failed - data was not saved despite HTTP 200!")
                    throw NSError(domain: "DatabaseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Child details update did not persist"])
                }
            }
            
        } catch {
            print("❌ Failed to save child details: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }
        
        print("Child details: \(name), age: \(age)")
    }
    
    func updateChild(childId: String, name: String, age: Int?, pronouns: String?) async throws {
        print("🔄 Attempting to update child: \(childId)")
        print("👶 Updated data: name=\(name), age=\(age ?? 0), pronouns=\(pronouns ?? "none")")
        
        let supabase = SupabaseManager.shared.client
        
        do {
            // Create update struct similar to insert pattern
            struct ChildUpdate: Codable {
                let name: String
                let age: Int?
                let pronouns: String?
                let updated_at: String
            }
            
            let updateData = ChildUpdate(
                name: name,
                age: age,
                pronouns: pronouns,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            let updateResponse = try await supabase
                .from("children")
                .update(updateData)
                .eq("id", value: childId)
                .execute()
            
            print("✅ Child update response: \(updateResponse)")
            
            // Verify the update worked by fetching the updated record
            let verificationResult: [Child] = try await supabase
                .from("children")
                .select("*")
                .eq("id", value: childId)
                .execute()
                .value
            
            if let updatedChild = verificationResult.first {
                print("✅ Child update verification:")
                print("   - Name: \(updatedChild.name ?? "no name")")
                print("   - Age: \(updatedChild.age ?? 0)")
                print("   - Pronouns: \(updatedChild.pronouns ?? "none")")
                print("✅ Child update successful!")
            } else {
                print("❌ Child update verification failed - record not found")
                throw NSError(domain: "DatabaseError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Updated child record not found"])
            }
            
        } catch {
            print("❌ Failed to update child: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Email/Password Authentication
    
    func signUp(email: String, password: String) async throws -> (userId: String, email: String?) {
        do {
            let session = try await SupabaseManager.shared.client.auth.signUp(
                email: email,
                password: password
            )
            print("Sign up successful: \(session.user.email ?? "No email")")
            return (userId: session.user.id.uuidString, email: session.user.email)
        } catch {
            print("Sign up error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws -> (userId: String, email: String?) {
        do {
            let session = try await SupabaseManager.shared.client.auth.signIn(
                email: email,
                password: password
            )
            print("Sign in successful: \(session.user.email ?? "No email")")
            return (userId: session.user.id.uuidString, email: session.user.email)
        } catch {
            print("Sign in error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signOut() async throws {
        do {
            try await SupabaseManager.shared.client.auth.signOut()
            print("Sign out successful")
        } catch {
            print("Sign out error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getCurrentUser() async -> User? {
        do {
            let user = try await SupabaseManager.shared.client.auth.user()
            return user
        } catch {
            print("Get current user error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Social Sign-In
    
    func signInWithGoogle() async throws {
        do {
            let url = try SupabaseManager.shared.client.auth.getOAuthSignInURL(
                provider: .google
            )
            print("Google sign in URL: \(url.absoluteString)")
            // In a real app, you would open this URL in a web view or Safari
        } catch {
            print("Google sign in error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signInWithApple() async throws {
        do {
            let url = try SupabaseManager.shared.client.auth.getOAuthSignInURL(
                provider: .apple
            )
            print("Apple sign in URL: \(url.absoluteString)")
            // In a real app, you would open this URL in a web view or Safari
        } catch {
            print("Apple sign in error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signInWithFacebook() async throws {
        do {
            let url = try SupabaseManager.shared.client.auth.getOAuthSignInURL(
                provider: .facebook
            )
            print("Facebook sign in URL: \(url.absoluteString)")
            // In a real app, you would open this URL in a web view or Safari
        } catch {
            print("Facebook sign in error: \(error.localizedDescription)")
            throw error
        }
    }
}