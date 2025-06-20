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
        Text("f")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
    }
}

struct AuthenticationView: View {
    let onAppleSignIn: () -> Void
    let onGoogleSignIn: () -> Void
    let onFacebookSignIn: () -> Void
    let onEmailSignIn: () -> Void
    let onBackTapped: () -> Void
    
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
                        Text("Sign in to continue")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorPalette.white)
                        
                        Text("Quick and secure access to your parenting co-pilot")
                            .font(.body)
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 12) {
                        CustomSocialButton(
                            customIcon: AnyView(AppleIcon()),
                            label: "Continue with Apple",
                            variant: .apple,
                            action: onAppleSignIn
                        )
                        
                        CustomSocialButton(
                            customIcon: AnyView(GoogleIcon()),
                            label: "Continue with Google",
                            variant: .google,
                            action: onGoogleSignIn
                        )
                        
                        CustomSocialButton(
                            customIcon: AnyView(FacebookIcon()),
                            label: "Continue with Facebook",
                            variant: .facebook,
                            action: onFacebookSignIn
                        )
                        
                        SocialButton(
                            icon: "envelope",
                            label: "Continue with Email",
                            variant: .email,
                            action: onEmailSignIn
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            
            Text("We protect your privacy and never share your data")
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
        onEmailSignIn: {},
        onBackTapped: {}
    )
}
