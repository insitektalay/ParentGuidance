import SwiftUI

struct AppearanceSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Title
            Text("Appearance")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(SemanticColors.tertiaryText)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            // Appearance Options
            VStack(spacing: 0) {
                // System Theme Option
                ThemeOptionRow(
                    title: "System",
                    subtitle: "Match device settings",
                    isSelected: preferredColorScheme == "system",
                    icon: "gear"
                ) {
                    preferredColorScheme = "system"
                    applyColorScheme()
                }
                
                Divider()
                    .background(SemanticColors.separator)
                    .padding(.leading, 56)
                
                // Light Theme Option
                ThemeOptionRow(
                    title: "Light",
                    subtitle: "Always use light theme",
                    isSelected: preferredColorScheme == "light",
                    icon: "sun.max.fill"
                ) {
                    preferredColorScheme = "light"
                    applyColorScheme()
                }
                
                Divider()
                    .background(SemanticColors.separator)
                    .padding(.leading, 56)
                
                // Dark Theme Option
                ThemeOptionRow(
                    title: "Dark",
                    subtitle: "Always use dark theme",
                    isSelected: preferredColorScheme == "dark",
                    icon: "moon.fill"
                ) {
                    preferredColorScheme = "dark"
                    applyColorScheme()
                }
            }
            .background(SemanticColors.secondaryBackground)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
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

struct ThemeOptionRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? SemanticColors.accent : SemanticColors.secondaryText)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.tertiaryText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SemanticColors.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        AppearanceSection()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SemanticColors.primaryBackground)
}