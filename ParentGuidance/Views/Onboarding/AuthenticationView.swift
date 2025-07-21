import SwiftUI

enum SocialButtonVariant {
    case apple
    case google
    case facebook
    case email
}

struct SocialButton: View {
    let icon: String
    let label: String
    let variant: SocialButtonVariant
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                
                Spacer()
                
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .apple:
            return Color.black
        case .google:
            return ColorPalette.white
        case .facebook:
            return Color(hex: "1877F2")
        case .email:
            return ColorPalette.terracotta
        }
    }
    
    private var textColor: Color {
        switch variant {
        case .apple, .facebook, .email:
            return ColorPalette.white
        case .google:
            return Color.black
        }
    }
    
    private var iconColor: Color {
        switch variant {
        case .apple, .facebook, .email:
            return ColorPalette.white
        case .google:
            return Color.black
        }
    }
}

struct CustomSocialButton: View {
    let customIcon: AnyView
    let label: String
    let variant: SocialButtonVariant
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                customIcon
                    .frame(width: 20, height: 20)
                
                Spacer()
                
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .apple:
            return Color.black
        case .google:
            return ColorPalette.white
        case .facebook:
            return Color(hex: "1877F2")
        case .email:
            return ColorPalette.terracotta
        }
    }
    
    private var textColor: Color {
        switch variant {
        case .apple, .facebook, .email:
            return ColorPalette.white
        case .google:
            return Color.black
        }
    }
}

struct AppleIcon: View {
    var body: some View {
        Image(systemName: "apple.logo")
            .font(.system(size: 20, weight: .medium))
    }
}

struct GoogleIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
            
            Text("G")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "4285F4"))
        }
    }
}

struct FacebookIcon: View {
    var body: some View {
        Text(String(localized: "common.letter.f"))
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
    }
}

struct AuthenticationView: View {
    let onAppleSignIn: () -> Void
    let onGoogleSignIn: () -> Void
    let onFacebookSignIn: () -> Void
    let onEmailSignIn: (String, String?) -> Void
    let onBackTapped: () -> Void
    
    // Test credentials
    private let testEmail = "test@example.com"
    private let testPassword = "password123"
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    Button(action: onBackTapped) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text(String(localized: "auth.signInTitle"))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorPalette.white)
                        
                        Text(String(localized: "auth.signInSubtitle"))
                            .font(.body)
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 12) {
                        CustomSocialButton(
                            customIcon: AnyView(AppleIcon()),
                            label: String(localized: "auth.continueWithApple"),
                            variant: .apple,
                            action: {
                                Task {
                                    do {
                                        try await AuthService.shared.signInWithApple()
                                        print("✅ Apple sign in successful")
                                        onAppleSignIn()
                                    } catch {
                                        print("❌ Apple sign in failed: \(error.localizedDescription)")
                                    }
                                }
                            }
                        )
                        
                        CustomSocialButton(
                            customIcon: AnyView(GoogleIcon()),
                            label: String(localized: "auth.continueWithGoogle"),
                            variant: .google,
                            action: {
                                Task {
                                    do {
                                        try await AuthService.shared.signInWithGoogle()
                                        print("✅ Google sign in successful")
                                        onGoogleSignIn()
                                    } catch {
                                        print("❌ Google sign in failed: \(error.localizedDescription)")
                                    }
                                }
                            }
                        )
                        
                        CustomSocialButton(
                            customIcon: AnyView(FacebookIcon()),
                            label: String(localized: "auth.continueWithFacebook"),
                            variant: .facebook,
                            action: {
                                Task {
                                    do {
                                        try await AuthService.shared.signInWithFacebook()
                                        print("✅ Facebook sign in successful")
                                        onFacebookSignIn()
                                    } catch {
                                        print("❌ Facebook sign in failed: \(error.localizedDescription)")
                                    }
                                }
                            }
                        )
                        
                        SocialButton(
                            icon: "envelope",
                            label: String(localized: "auth.continueWithEmail"),
                            variant: .email,
                            action: {
                                Task {
                                    do {
                                        let userInfo = try await AuthService.shared.signIn(email: testEmail, password: testPassword)
                                        print("✅ Email sign in successful with \(testEmail)")
                                        print("🎯 User ID: \(userInfo.userId)")
                                        onEmailSignIn(userInfo.userId, userInfo.email)
                                    } catch {
                                        print("❌ Email sign in failed: \(error.localizedDescription)")
                                        // Try sign up if sign in fails
                                        do {
                                            let userInfo = try await AuthService.shared.signUp(email: testEmail, password: testPassword)
                                            print("✅ Email sign up successful with \(testEmail)")
                                            print("🎯 User ID: \(userInfo.userId)")
                                            onEmailSignIn(userInfo.userId, userInfo.email)
                                        } catch {
                                            print("❌ Email sign up also failed: \(error.localizedDescription)")
                                        }
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            
            Text(String(localized: "auth.privacyNote"))
                .font(.body)
                .foregroundColor(ColorPalette.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .ignoresSafeArea()
    }
}

#Preview {
    AuthenticationView(
        onAppleSignIn: {},
        onGoogleSignIn: {},
        onFacebookSignIn: {},
        onEmailSignIn: { _, _ in },
        onBackTapped: {}
    )
}
