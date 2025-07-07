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
                            Text(isActive ? "Active Framework" : "Framework Recommendation")
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
                    Text("This framework was selected based on your specific situation patterns and is designed to provide consistent strategies for your family.")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.navy.opacity(0.6))
                        .lineSpacing(2)
                    
                    // Action buttons
                    VStack(alignment: .leading, spacing: 8) {
                        if isActive {
                            // Active framework buttons
                            HStack(spacing: 8) {
                                Button(action: onLearnMore) {
                                    Text("Framework Guide")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ColorPalette.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(ColorPalette.brightBlue)
                                        .clipShape(Capsule())
                                }
                                
                                Button(action: {}) {
                                    Text("View Progress")
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
                                    Text("Activate Framework")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ColorPalette.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(ColorPalette.terracotta)
                                        .clipShape(Capsule())
                                }
                                
                                Button(action: onLearnMore) {
                                    Text("Learn More")
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
    
    private let familyId = "5627b7a3-3ba8-4f1b-92a8-ba0e460863e5" // TODO: Get from user context
    
    init() {
        Task {
            await loadFramework()
        }
    }
    
    @MainActor
    func loadFramework() async {
        isLoading = true
        errorMessage = nil
        
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
            // Here we would use the framework ID from database in a real implementation
            // For now, we'll simulate activation by updating the local state
            isActive = true
            print("✅ Framework activated: \(framework.frameworkName)")
            
            // TODO: Call FrameworkStorageService.shared.activateFramework(id: framework.id)
            
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
    @StateObject private var frameworkState = FrameworkAlertState()
    
    var body: some View {
        Group {
            if frameworkState.isLoading {
                // Loading state
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading framework...")
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
                    Text("Unable to load frameworks")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.navy)
                    
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.navy.opacity(0.6))
                    
                    Button("Try Again") {
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
                    Text("No Framework Recommendations Yet")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ColorPalette.navy)
                    
                    Text("Generate a personalized parenting framework by selecting multiple situations from your Library and tapping 'Set Up Framework'.")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.navy.opacity(0.6))
                        .lineSpacing(2)
                    
                    Button("Go to Library") {
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
