//
//  FrameworkRecommendationView.swift
//  ParentGuidance
//
//  Created by alex kerss on 07/07/2025.
//

import SwiftUI

struct FrameworkRecommendationView: View {
    let framework: FrameworkRecommendation
    let isActive: Bool
    let onActivate: () -> Void
    let onLearnMore: () -> Void
    let onDismiss: () -> Void
    
    init(
        framework: FrameworkRecommendation,
        isActive: Bool = false,
        onActivate: @escaping () -> Void = {},
        onLearnMore: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void = {}
    ) {
        self.framework = framework
        self.isActive = isActive
        self.onActivate = onActivate
        self.onLearnMore = onLearnMore
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                // Left border - different color based on state
                Rectangle()
                    .fill(isActive ? ColorPalette.brightBlue : ColorPalette.terracotta)
                    .frame(width: 4)
                
                // Card content
                VStack(alignment: .leading, spacing: 16) {
                    // Status indicator and title
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(isActive ? String(localized: "alerts.framework.active") : String(localized: "alerts.framework.recommendation"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isActive ? ColorPalette.brightBlue : ColorPalette.terracotta)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background((isActive ? ColorPalette.brightBlue : ColorPalette.terracotta).opacity(0.1))
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            if !isActive {
                                Button(action: onDismiss) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(ColorPalette.navy.opacity(0.6))
                                }
                            }
                        }
                        
                        Text(framework.frameworkName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(ColorPalette.navy)
                    }
                    
                    // Framework description
                    Text(framework.notificationText)
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.navy.opacity(0.8))
                        .lineSpacing(2)
                    
                    // Framework type description if available
                    if let frameworkType = framework.frameworkType {
                        Text(frameworkType.description)
                            .font(.system(size: 14))
                            .foregroundColor(ColorPalette.navy.opacity(0.6))
                            .lineSpacing(2)
                    }
                    
                    // Disclaimer
                    Text(String(localized: "alerts.framework.disclaimer"))
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.navy.opacity(0.6))
                        .lineSpacing(2)
                    
                    // Action buttons
                    VStack(alignment: .leading, spacing: 8) {
                        if isActive {
                            // Active framework buttons
                            HStack(spacing: 8) {
                                Button(action: onLearnMore) {
                                    Text(String(localized: "alerts.framework.guide"))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ColorPalette.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(ColorPalette.brightBlue)
                                        .clipShape(Capsule())
                                }
                                
                                Button(action: {}) {
                                    Text(String(localized: "alerts.framework.progress"))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ColorPalette.brightBlue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(ColorPalette.brightBlue.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        } else {
                            // Recommendation buttons
                            HStack(spacing: 8) {
                                Button(action: onActivate) {
                                    Text(String(localized: "alerts.framework.activate"))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ColorPalette.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(ColorPalette.terracotta)
                                        .clipShape(Capsule())
                                }
                                
                                Button(action: onLearnMore) {
                                    Text(String(localized: "alerts.framework.learnMore"))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ColorPalette.terracotta)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(ColorPalette.terracotta.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(ColorPalette.cream)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
}

// MARK: - Framework Alert State Management

class FrameworkAlertState: ObservableObject {
    @Published var currentFramework: FrameworkRecommendation?
    @Published var isActive: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let familyId: String?
    
    init(familyId: String?) {
        self.familyId = familyId
        Task {
            await loadFramework()
        }
    }
    
    @MainActor
    func loadFramework() async {
        isLoading = true
        errorMessage = nil
        
        guard let familyId = familyId else {
            print("❌ No family ID available for FrameworkAlertState")
            isLoading = false
            return
        }
        
        do {
            if let framework = try await FrameworkStorageService.shared.getActiveFramework(familyId: familyId) {
                currentFramework = framework
                isActive = true
                print("✅ Loaded active framework: \(framework.frameworkName)")
            } else {
                // Check for most recent framework recommendation
                let frameworks = try await FrameworkStorageService.shared.getFrameworkHistory(familyId: familyId)
                if let latestFramework = frameworks.first {
                    currentFramework = latestFramework
                    isActive = false
                    print("📋 Loaded recent framework recommendation: \(latestFramework.frameworkName)")
                } else {
                    currentFramework = nil
                    isActive = false
                    print("📭 No frameworks found for family")
                }
            }
        } catch {
            print("❌ Failed to load framework: \(error)")
            errorMessage = "Unable to load framework recommendations"
        }
        
        isLoading = false
    }
    
    @MainActor
    func activateFramework() async {
        guard let framework = currentFramework else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Activate framework in database
            try await FrameworkStorageService.shared.activateFramework(id: framework.id)
            isActive = true
            print("✅ Framework activated in database: \(framework.frameworkName)")
            
        } catch {
            print("❌ Failed to activate framework: \(error)")
            errorMessage = "Unable to activate framework"
        }
        
        isLoading = false
    }
    
    @MainActor
    func dismissFramework() async {
        // For now, just hide the current framework
        currentFramework = nil
        isActive = false
        
        // TODO: In a real implementation, this might mark the framework as dismissed
        // or move it to a "dismissed" state in the database
        print("📝 Framework dismissed")
    }
}

struct FrameworkAlertContainer: View {
    let familyId: String?
    @StateObject private var frameworkState: FrameworkAlertState
    
    init(familyId: String? = nil) {
        self.familyId = familyId
        self._frameworkState = StateObject(wrappedValue: FrameworkAlertState(familyId: familyId))
    }
    
    var body: some View {
        Group {
            if frameworkState.isLoading {
                // Loading state
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(String(localized: "alerts.framework.loading"))
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.navy.opacity(0.6))
                }
                .padding()
                .background(ColorPalette.cream)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                
            } else if let errorMessage = frameworkState.errorMessage {
                // Error state
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "alerts.framework.error.title"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.navy)
                    
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.navy.opacity(0.6))
                    
                    Button(String(localized: "common.tryAgain")) {
                        Task {
                            await frameworkState.loadFramework()
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorPalette.terracotta)
                    .padding(.top, 4)
                }
                .padding(16)
                .background(ColorPalette.cream)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                
            } else if let framework = frameworkState.currentFramework {
                // Framework display
                FrameworkRecommendationView(
                    framework: framework,
                    isActive: frameworkState.isActive,
                    onActivate: {
                        Task {
                            await frameworkState.activateFramework()
                        }
                    },
                    onLearnMore: {
                        print("Learn more about \(framework.frameworkName)")
                        // TODO: Navigate to framework guide or information
                    },
                    onDismiss: {
                        Task {
                            await frameworkState.dismissFramework()
                        }
                    }
                )
                
            } else {
                // Empty state - no frameworks
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "alerts.framework.empty.title"))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ColorPalette.navy)
                    
                    Text(String(localized: "alerts.framework.empty.subtitle"))
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.navy.opacity(0.6))
                        .lineSpacing(2)
                    
                    Button(String(localized: "alerts.framework.goToLibrary")) {
                        print("Navigate to Library tab")
                        // TODO: Navigate to Library tab
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorPalette.terracotta)
                    .padding(.top, 4)
                }
                .padding(16)
                .background(ColorPalette.cream)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            Task {
                await frameworkState.loadFramework()
            }
        }
    }
}

#Preview {
    VStack {
        // Recommended framework
        FrameworkRecommendationView(
            framework: FrameworkRecommendation(
                frameworkName: "Zones of Regulation",
                notificationText: "Based on your situation patterns, the Zones of Regulation framework could help your child understand and manage their emotional states through color-coded zones."
            ),
            isActive: false
        )
        
        // Active framework
        FrameworkRecommendationView(
            framework: FrameworkRecommendation(
                frameworkName: "Emotion Coaching",
                notificationText: "You're currently using the Emotion Coaching framework to help your child identify and process their feelings in challenging moments."
            ),
            isActive: true
        )
    }
    .padding()
    .background(ColorPalette.navy)
}
