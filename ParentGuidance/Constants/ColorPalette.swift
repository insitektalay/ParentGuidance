import SwiftUI

// MARK: - Original Color Palette
struct ColorPalette {
    static let navy = Color(hex: "2B2D42")
    static let terracotta = Color(hex: "C4816C")
    static let cream = Color(hex: "F7F3E9")
    static let brightBlue = Color(hex: "4285F4")
    static let white = Color.white
    
    // Additional colors for light theme
    static let darkGray = Color(hex: "1C1C1E")
    static let mediumGray = Color(hex: "3C3C43")
    static let lightGray = Color(hex: "C7C7CC")
    static let systemGray6 = Color(hex: "F2F2F7")
}

// MARK: - Semantic Colors using @Environment
struct SemanticColors {
    // Backgrounds - Using dynamic colors that adapt to color scheme
    static var primaryBackground: Color {
        Color("PrimaryBackground", bundle: nil)
    }
    
    static var secondaryBackground: Color {
        Color("SecondaryBackground", bundle: nil)
    }
    
    static var tertiaryBackground: Color {
        Color("TertiaryBackground", bundle: nil)
    }
    
    static var cardBackground: Color {
        Color("CardBackground", bundle: nil)
    }
    
    // Text
    static var primaryText: Color {
        Color("PrimaryText", bundle: nil)
    }
    
    static var secondaryText: Color {
        Color("SecondaryText", bundle: nil)
    }
    
    static var tertiaryText: Color {
        Color("TertiaryText", bundle: nil)
    }
    
    // Accent colors (consistent across themes)
    static var accent: Color {
        ColorPalette.terracotta
    }
    
    static var accentBlue: Color {
        ColorPalette.brightBlue
    }
    
    // Borders and separators
    static var separator: Color {
        Color("Separator", bundle: nil)
    }
    
    static var border: Color {
        Color("Border", bundle: nil)
    }
    
    // System colors
    static var systemBackground: Color {
        Color("SystemBackground", bundle: nil)
    }
    
    static var systemGroupedBackground: Color {
        Color("SystemGroupedBackground", bundle: nil)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Shadow Definitions for Light Theme
extension View {
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    func subtleShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
    
    func elevatedShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
    }
    
}