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
        .background(Color(red: 0.21, green: 0.22, blue: 0.33)) // #363853 equivalent
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
        )
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
            Text("Are you sure you want to deactivate your current framework? You can always reactivate it later from your framework recommendations.")
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        HStack(alignment: .center, spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(ColorPalette.white)
            
            Text("Loading framework status...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white)
            
            Spacer()
        }
    }
    
    private func activeFrameworkView(framework: FrameworkRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and active framework name
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(ColorPalette.brightBlue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Active Framework")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ColorPalette.brightBlue)
                    
                    Text(framework.frameworkName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ColorPalette.white)
                }
                
                Spacer()
            }
            
            // Framework description/type if available
            if let frameworkType = framework.frameworkType {
                Text(frameworkType.description)
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.white.opacity(0.8))
                    .lineLimit(2)
            } else {
                Text("Your personalized parenting framework is now active and guiding your approach.")
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            // Action buttons for active framework
            HStack(spacing: 12) {
                Button(action: onViewTools) {
                    Text("Framework Guide")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(ColorPalette.brightBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: {
                    frameworkState.showingDeactivationAlert = true
                }) {
                    Text("Deactivate")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.terracotta)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ColorPalette.terracotta, lineWidth: 1)
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
                    .foregroundColor(ColorPalette.white)
                
                Text("Foundational Framework Not Yet Established")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ColorPalette.white)
                
                Spacer()
            }
            
            // Description
            Text("Select situations from your library to generate a personalized parenting framework recommendation")
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.8))
                .lineLimit(nil)
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onViewTools) {
                    Text("View tools")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(ColorPalette.terracotta)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: onSetupFramework) {
                    Text("Set Up Framework")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.terracotta)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ColorPalette.terracotta, lineWidth: 1)
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
        .background(ColorPalette.navy)
}