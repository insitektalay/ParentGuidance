import SwiftUI

struct ThemeSelectionView: View {
    @Binding var isPresented: Bool
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text("Choose Theme")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Text("Select your preferred appearance")
                        .font(.system(size: 16))
                        .foregroundColor(SemanticColors.secondaryText)
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
                
                // Theme Options
                VStack(spacing: 16) {
                    ThemeOption(
                        title: "System",
                        description: "Automatically match your device settings",
                        icon: "gear",
                        isSelected: preferredColorScheme == "system"
                    ) {
                        preferredColorScheme = "system"
                        applyColorScheme()
                    }
                    
                    ThemeOption(
                        title: "Light",
                        description: "Always use light appearance",
                        icon: "sun.max.fill",
                        isSelected: preferredColorScheme == "light"
                    ) {
                        preferredColorScheme = "light"
                        applyColorScheme()
                    }
                    
                    ThemeOption(
                        title: "Dark",
                        description: "Always use dark appearance",
                        icon: "moon.fill",
                        isSelected: preferredColorScheme == "dark"
                    ) {
                        preferredColorScheme = "dark"
                        applyColorScheme()
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Done Button
                Button(action: { isPresented = false }) {
                    Text("Done")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(SemanticColors.accent)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(SemanticColors.primaryBackground)
            .navigationBarHidden(true)
        }
    }
    
    private func applyColorScheme() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        
        windowScene.windows.forEach { window in
            switch preferredColorScheme {
            case "light":
                window.overrideUserInterfaceStyle = .light
            case "dark":
                window.overrideUserInterfaceStyle = .dark
            default:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
}

struct ThemeOption: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? SemanticColors.accent.opacity(0.1) : SemanticColors.secondaryBackground)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? SemanticColors.accent : SemanticColors.secondaryText)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.tertiaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(SemanticColors.accent)
                }
            }
            .padding(16)
            .background(SemanticColors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? SemanticColors.accent : SemanticColors.border, lineWidth: isSelected ? 2 : 1)
            )
            .if(colorScheme == .light && !isSelected) { view in
                view.cardShadow()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// View extension if not already present
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    ThemeSelectionView(isPresented: .constant(true))
}