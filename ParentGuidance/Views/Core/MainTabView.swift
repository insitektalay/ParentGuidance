import SwiftUI

enum Tab: String, CaseIterable {
    case today = "today"
    case new = "new"
    case library = "library"
    case alerts = "alerts"
    case settings = "settings"
    
    var title: String {
        switch self {
        case .today: return String(localized: "tab.today")
        case .new: return String(localized: "tab.new")
        case .library: return String(localized: "tab.library")
        case .alerts: return String(localized: "tab.alerts")
        case .settings: return String(localized: "tab.settings")
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
            Text(String(localized: "screen.today.title"))
                .font(.title)
                .foregroundColor(ColorPalette.white)
        }
    }
}

struct NewScreen: View {
    var body: some View {
        ZStack {
            ColorPalette.navy.ignoresSafeArea()
            Text(String(localized: "screen.new.title"))
                .font(.title)
                .foregroundColor(ColorPalette.white)
        }
    }
}

struct LibraryScreen: View {
    var body: some View {
        ZStack {
            ColorPalette.navy.ignoresSafeArea()
            Text(String(localized: "screen.library.title"))
                .font(.title)
                .foregroundColor(ColorPalette.white)
        }
    }
}

struct AlertsScreen: View {
    var body: some View {
        ZStack {
            ColorPalette.navy.ignoresSafeArea()
            Text(String(localized: "screen.alerts.title"))
                .font(.title)
                .foregroundColor(ColorPalette.white)
        }
    }
}


struct MainTabView: View {
    @State private var activeTab: Tab = .new
    @StateObject private var tabNavigationManager = TabNavigationManager.shared
    @EnvironmentObject var appCoordinator: AppCoordinator

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Fixed child header - always stays at top
                ChildHeader(childName: appCoordinator.children.first?.name ?? "Child")
                    .background(ColorPalette.navy)
                    .zIndex(1000)
                
                // Scrollable content area
                ScrollView {
                    VStack {
                        Group {
                            switch activeTab {
                            case .today:
                                NavigationStack {
                                    TodayViewController(onNavigateToNewTab: {
                                        activeTab = .new
                                    })
                                }
                            case .new:
                                NewSituationView()
                            case .library:
                                LibraryView()
                            case .alerts:
                                AlertView()
                            case .settings:
                                SettingsView()
                            }
                        }
                        .frame(minHeight: geometry.size.height - 140) // Account for header and tab bar
                    }
                }
                .background(ColorPalette.navy)
                
                // Fixed tab bar - always stays at bottom
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
                .zIndex(1000)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onReceive(tabNavigationManager.$requestedTab) { requestedTab in
            if let tab = requestedTab {
                print("📱 Handling navigation request to: \(tab.title)")
                activeTab = tab
                tabNavigationManager.clearNavigationRequest()
            }
        }
    }
}

#Preview {
    MainTabView()
}
