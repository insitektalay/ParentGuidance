import SwiftUI

struct ThemeDemoView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingThemeOptions = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Theme Toggle Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theme Settings")
                            .font(.headline)
                            .foregroundColor(SemanticColors.primaryText)
                        
                        // Current Theme Display
                        HStack {
                            Text("Current Theme:")
                                .foregroundColor(SemanticColors.secondaryText)
                            Spacer()
                            Text(themeManager.currentTheme == .dark ? "Dark" : "Light")
                                .foregroundColor(SemanticColors.accent)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .background(SemanticColors.cardBackground)
                        .cornerRadius(12)
                        .if(themeManager.currentTheme == .light) { view in
                            view.cardShadow()
                        }
                        
                        // Theme Toggle Button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                themeManager.toggleTheme()
                            }
                        }) {
                            HStack {
                                Image(systemName: themeManager.currentTheme == .dark ? "sun.max.fill" : "moon.fill")
                                Text("Switch to \(themeManager.currentTheme == .dark ? "Light" : "Dark") Theme")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(SemanticColors.primaryText)
                            .padding()
                            .background(SemanticColors.accent.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // System Theme Toggle
                        Toggle(isOn: $themeManager.isSystemThemeEnabled) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Follow System Theme")
                            }
                            .foregroundColor(SemanticColors.primaryText)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: SemanticColors.accent))
                        .padding()
                        .background(SemanticColors.cardBackground)
                        .cornerRadius(12)
                        .if(themeManager.currentTheme == .light) { view in
                            view.cardShadow()
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .background(SemanticColors.separator)
                        .padding(.horizontal)
                    
                    // Sample Components
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sample Components")
                            .font(.headline)
                            .foregroundColor(SemanticColors.primaryText)
                            .padding(.horizontal)
                        
                        // Sample Situation Cards
                        VStack(spacing: 12) {
                            SituationCard(
                                emoji: "🦷",
                                title: "Morning teeth brushing",
                                date: "Today",
                                isFavorited: false,
                                onToggleFavorite: {},
                                onDelete: {}
                            )
                            
                            SituationCard(
                                emoji: "😴",
                                title: "Bedtime routine struggles",
                                date: "Yesterday",
                                isFavorited: true,
                                onToggleFavorite: {},
                                onDelete: {}
                            )
                            
                            SituationCard(
                                emoji: "🍽️",
                                title: "Dinner time negotiations",
                                date: "Oct 15",
                                isFavorited: false,
                                onToggleFavorite: {},
                                onDelete: {}
                            )
                        }
                        .padding(.horizontal)
                        
                        // Color Palette Preview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color Palette")
                                .font(.subheadline)
                                .foregroundColor(SemanticColors.secondaryText)
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                ColorRow(name: "Primary Background", color: SemanticColors.primaryBackground)
                                ColorRow(name: "Secondary Background", color: SemanticColors.secondaryBackground)
                                ColorRow(name: "Card Background", color: SemanticColors.cardBackground)
                                ColorRow(name: "Primary Text", color: SemanticColors.primaryText, onLight: true)
                                ColorRow(name: "Secondary Text", color: SemanticColors.secondaryText, onLight: true)
                                ColorRow(name: "Accent", color: SemanticColors.accent)
                                ColorRow(name: "Border", color: SemanticColors.border)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(SemanticColors.primaryBackground)
            .navigationTitle("Theme Demo")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ColorRow: View {
    let name: String
    let color: Color
    var onLight: Bool = false
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(SemanticColors.border, lineWidth: 1)
                )
                .background(onLight ? Color.white : Color.clear)
            
            Text(name)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.primaryText)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// Extension for conditional modifiers (if not already in project)
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
    ThemeDemoView()
        .environmentObject(ThemeManager.shared)
}