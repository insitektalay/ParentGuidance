import Foundation
import Supabase

class AuthService {
    static let shared = AuthService()
    
    private init() {}
    
    // MARK: - Email/Password Authentication
    
    func signUp(email: String, password: String) async throws {
        do {
            let session = try await SupabaseManager.shared.client.auth.signUp(
                email: email,
                password: password
            )
            print("Sign up successful: \(session.user.email ?? "No email")")
        } catch {
            print("Sign up error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let session = try await SupabaseManager.shared.client.auth.signIn(
                email: email,
                password: password
            )
            print("Sign in successful: \(session.user.email ?? "No email")")
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
            let url = try await SupabaseManager.shared.client.auth.getOAuthSignInURL(
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
            let url = try await SupabaseManager.shared.client.auth.getOAuthSignInURL(
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
            let url = try await SupabaseManager.shared.client.auth.getOAuthSignInURL(
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