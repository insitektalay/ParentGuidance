import SwiftUI

enum Tab: String, CaseIterable {
    case today = "today"
    case new = "new"
    case library = "library"
    case alerts = "alerts"
    case settings = "settings"
    
    var title: String {
        switch self {
        case .today: return "Today"
        case .new: return "New"
        case .library: return "Library"
        case .alerts: return "Alerts"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .today: return "house"
        case .new: return "plus"
        case .library: return "book"
        case .alerts: return "bell"
        case .settings: return "gearshape"
        }
    }
}

struct TabButton: View {
    let tab: Tab
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isActive {
                        Circle()
                            .fill(ColorPalette.terracotta)
                            .frame(width: 40, height: 40)
                    }
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isActive ? ColorPalette.white : ColorPalette.white.opacity(0.5))
                }
                .frame(width: 40, height: 40)
                
                Text(tab.title)
                    .font(.system(size: 12))
                    .foregroundColor(isActive ? ColorPalette.terracotta : ColorPalette.white.opacity(0.5))
            }
        }
    }
}

struct TodayScreen: View {
    var body: some View {
        ZStack {
            ColorPalette.navy.ignoresSafeArea()
            Text("Today Screen")
                .font(.title)
                .foregroundColor(ColorPalette.white)
        }
    }
}

struct NewScreen: View {
    var body: some View {
        ZStack {
            ColorPalette.navy.ignoresSafeArea()
            Text("New Screen")
                .font(.title)
                .foregroundColor(ColorPalette.white)
        }
    }
}

struct LibraryScreen: View {
    var body: some View {
        ZStack {
            ColorPalette.navy.ignoresSafeArea()
            Text("Library Screen")
                .font(.title)
                .foregroundColor(ColorPalette.white)
        }
    }
}

struct AlertsScreen: View {
    var body: some View {
        ZStack {
            ColorPalette.navy.ignoresSafeArea()
            Text("Alerts Screen")
                .font(.title)
                .foregroundColor(ColorPalette.white)
        }
    }
}

struct SettingsScreen: View {
    var body: some View {
        ZStack {
            ColorPalette.navy.ignoresSafeArea()
            Text("Settings Screen")
                .font(.title)
                .foregroundColor(ColorPalette.white)
        }
    }
}

struct MainTabView: View {
    @State private var activeTab: Tab = .new

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area
            Group {
                switch activeTab {
                case .today:
                    TodayScreen()
                case .new:
                    NewSituationView()
                case .library:
                    LibraryScreen()
                case .alerts:
                    AlertsScreen()
                case .settings:
                    SettingsScreen()
                }
            }

            // Tab bar
            HStack {
                ForEach(Tab.allCases, id: \.self) { tab in
                    TabButton(
                        tab: tab,
                        isActive: activeTab == tab,
                        action: {
                            activeTab = tab
                        }
                    )

                    if tab != Tab.allCases.last {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 20)
            .background(Color(hex: "1F2133"))
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

#Preview {
    MainTabView()
}
