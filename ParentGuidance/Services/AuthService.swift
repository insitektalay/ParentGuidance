import Foundation
import Supabase

class AuthService {
    static let shared = AuthService()
    
    private init() {}
    
    // MARK: - Email/Password Authentication
    
    func signUp(email: String, password: String) async throws {
        do {
            let response = try await SupabaseManager.shared.client.auth.signUp(
                email: email,
                password: password
            )
            print("Sign up successful: \(response.user?.email ?? "No email")")
        } catch {
            print("Sign up error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let response = try await SupabaseManager.shared.client.auth.signIn(
                email: email,
                password: password
            )
            print("Sign in successful: \(response.user?.email ?? "No email")")
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
            let response = try await SupabaseManager.shared.client.auth.signInWithOAuth(
                provider: .google
            )
            print("Google sign in successful: \(response.url?.absoluteString ?? "No URL")")
        } catch {
            print("Google sign in error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signInWithApple() async throws {
        do {
            let response = try await SupabaseManager.shared.client.auth.signInWithOAuth(
                provider: .apple
            )
            print("Apple sign in successful: \(response.url?.absoluteString ?? "No URL")")
        } catch {
            print("Apple sign in error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signInWithFacebook() async throws {
        do {
            let response = try await SupabaseManager.shared.client.auth.signInWithOAuth(
                provider: .facebook
            )
            print("Facebook sign in successful: \(response.url?.absoluteString ?? "No URL")")
        } catch {
            print("Facebook sign in error: \(error.localizedDescription)")
            throw error
        }
    }
}