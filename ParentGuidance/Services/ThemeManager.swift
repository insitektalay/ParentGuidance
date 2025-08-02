import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme {
        didSet {
            saveThemePreference()
            applyTheme()
        }
    }
    
    @Published var isSystemThemeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSystemThemeEnabled, forKey: "isSystemThemeEnabled")
            if isSystemThemeEnabled {
                updateToSystemTheme()
            }
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Load saved theme preference
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = Theme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .dark // Default to dark theme
        }
        
        // Load system theme preference
        self.isSystemThemeEnabled = UserDefaults.standard.bool(forKey: "isSystemThemeEnabled")
        
        // Observe system theme changes
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                if self?.isSystemThemeEnabled == true {
                    self?.updateToSystemTheme()
                }
            }
            .store(in: &cancellables)
    }
    
    private func saveThemePreference() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
    }
    
    private func applyTheme() {
        // This will force all windows to update their appearance
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        
        windowScene.windows.forEach { window in
            if !isSystemThemeEnabled {
                window.overrideUserInterfaceStyle = currentTheme.userInterfaceStyle
            } else {
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
    
    private func updateToSystemTheme() {
        let userInterfaceStyle = UITraitCollection.current.userInterfaceStyle
        currentTheme = userInterfaceStyle == .dark ? .dark : .light
        
        // Reset override to follow system
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        windowScene.windows.forEach { window in
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    func toggleTheme() {
        currentTheme = currentTheme == .dark ? .light : .dark
        isSystemThemeEnabled = false
    }
}

// MARK: - Theme Environment Key
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: Theme = .dark
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extensions
extension View {
    func themed() -> some View {
        self
            .environmentObject(ThemeManager.shared)
            .environment(\.theme, ThemeManager.shared.currentTheme)
    }
    
    // Convenience modifiers for theme-aware styling
    func themedBackground(_ style: BackgroundStyle = .primary) -> some View {
        self.background(style.color)
    }
    
    func themedForeground(_ style: TextStyle = .primary) -> some View {
        self.foregroundColor(style.color)
    }
}

// MARK: - Background Styles
enum BackgroundStyle {
    case primary
    case secondary
    case tertiary
    case card
    case system
    case systemGrouped
    
    var color: Color {
        switch self {
        case .primary:
            return SemanticColors.primaryBackground
        case .secondary:
            return SemanticColors.secondaryBackground
        case .tertiary:
            return SemanticColors.tertiaryBackground
        case .card:
            return SemanticColors.cardBackground
        case .system:
            return SemanticColors.systemBackground
        case .systemGrouped:
            return SemanticColors.systemGroupedBackground
        }
    }
}

// MARK: - Text Styles
enum TextStyle {
    case primary
    case secondary
    case tertiary
    case accent
    case accentBlue
    
    var color: Color {
        switch self {
        case .primary:
            return SemanticColors.primaryText
        case .secondary:
            return SemanticColors.secondaryText
        case .tertiary:
            return SemanticColors.tertiaryText
        case .accent:
            return SemanticColors.accent
        case .accentBlue:
            return SemanticColors.accentBlue
        }
    }
}