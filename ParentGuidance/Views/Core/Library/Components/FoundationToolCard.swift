import SwiftUI

// MARK: - Framework State Management

class FoundationFrameworkState: ObservableObject {
    @Published var currentFramework: FrameworkRecommendation?
    @Published var isLoading: Bool = false
    @Published var showingDeactivationAlert: Bool = false
    
    private let familyId: String?
    
    init(familyId: String?) {
        self.familyId = familyId
        Task {
            await loadActiveFramework()
        }
    }
    
    @MainActor
    func loadActiveFramework() async {
        isLoading = true
        
        guard let familyId = familyId else {
            print("❌ No family ID available for FoundationFrameworkState")
            isLoading = false
            return
        }
        
        do {
            currentFramework = try await FrameworkStorageService.shared.getActiveFramework(familyId: familyId)
            if let framework = currentFramework {
                print("✅ Loaded active framework: \(framework.frameworkName)")
            } else {
                print("📭 No active framework found")
            }
        } catch {
            print("❌ Failed to load active framework: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func deactivateFramework() async {
        guard let framework = currentFramework else { return }
        
        isLoading = true
        
        do {
            try await FrameworkStorageService.shared.deactivateFramework(id: framework.id)
            currentFramework = nil
            print("✅ Framework deactivated: \(framework.frameworkName)")
        } catch {
            print("❌ Failed to deactivate framework: \(error)")
        }
        
        isLoading = false
        showingDeactivationAlert = false
    }
}

struct FoundationToolCard: View {
    let onViewTools: () -> Void
    let onSetupFramework: () -> Void
    let familyId: String?
    
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var frameworkState: FoundationFrameworkState
    
    init(
        familyId: String? = nil,
        onViewTools: @escaping () -> Void = {},
        onSetupFramework: @escaping () -> Void = {}
    ) {
        self.onViewTools = onViewTools
        self.onSetupFramework = onSetupFramework
        self.familyId = familyId
        self._frameworkState = StateObject(wrappedValue: FoundationFrameworkState(familyId: familyId))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if frameworkState.isLoading {
                loadingView
            } else if let framework = frameworkState.currentFramework {
                activeFrameworkView(framework: framework)
            } else {
                inactiveFrameworkView
            }
        }
        .padding(16)
        .background(SemanticColors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SemanticColors.border, lineWidth: 1)
        )
        .if(colorScheme == .light) { view in
            view.cardShadow()
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            Task {
                await frameworkState.loadActiveFramework()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task {
                await frameworkState.loadActiveFramework()
            }
        }
        .alert("Deactivate Framework", isPresented: $frameworkState.showingDeactivationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Deactivate", role: .destructive) {
                Task {
                    await frameworkState.deactivateFramework()
                }
            }
        } message: {
            Text(String(localized: "foundation.deactivate.message"))
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        HStack(alignment: .center, spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(SemanticColors.primaryText)
            
            Text(String(localized: "foundation.loading"))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SemanticColors.primaryText)
            
            Spacer()
        }
    }
    
    private func activeFrameworkView(framework: FrameworkRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and active framework name
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(SemanticColors.accentBlue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "foundation.active.title"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SemanticColors.accentBlue)
                    
                    Text(framework.frameworkName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(SemanticColors.primaryText)
                }
                
                Spacer()
            }
            
            // Framework description/type if available
            if let frameworkType = framework.frameworkType {
                Text(frameworkType.description)
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.secondaryText)
                    .lineLimit(2)
            } else {
                Text(String(localized: "foundation.active.description"))
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.secondaryText)
                    .lineLimit(2)
            }
            
            // Action buttons for active framework
            HStack(spacing: 12) {
                Button(action: onViewTools) {
                    Text(String(localized: "foundation.active.guide"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(SemanticColors.accentBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: {
                    frameworkState.showingDeactivationAlert = true
                }) {
                    Text(String(localized: "foundation.active.deactivate"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(SemanticColors.accent, lineWidth: 1)
                        )
                }
                
                Spacer()
            }
        }
    }
    
    private var inactiveFrameworkView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "target")
                    .font(.system(size: 20))
                    .foregroundColor(SemanticColors.primaryText)
                
                Text(String(localized: "foundation.inactive.title"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
            }
            
            // Description
            Text(String(localized: "foundation.inactive.description"))
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.secondaryText)
                .lineLimit(nil)
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onViewTools) {
                    Text(String(localized: "foundation.inactive.viewTools"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(SemanticColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: onSetupFramework) {
                    Text(String(localized: "foundation.inactive.setup"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(SemanticColors.accent, lineWidth: 1)
                        )
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    FoundationToolCard()
        .padding()
        .background(SemanticColors.primaryBackground)
}