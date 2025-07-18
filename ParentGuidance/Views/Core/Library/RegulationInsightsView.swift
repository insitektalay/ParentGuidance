//
//  RegulationInsightsView.swift
//  ParentGuidance
//
//  Created by alex kerss on 18/07/2025.
//

import SwiftUI

struct RegulationInsightsView: View {
    let familyId: String
    @Environment(\.dismiss) private var dismiss
    @State private var insightCounts: [RegulationCategory: Int] = [:]
    @State private var isLoading = true
    @State private var hasError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .center, spacing: 12) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(ColorPalette.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Text("How Your Child Responds")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                // Content
                if isLoading {
                    loadingView
                } else if hasError {
                    errorView
                } else {
                    categoryListView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                await loadInsightCounts()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .foregroundColor(ColorPalette.white.opacity(0.8))
            
            Text("Loading insights...")
                .font(.system(size: 16))
                .foregroundColor(ColorPalette.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Text("Unable to load insights")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text("Please try again later")
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
            
            Button("Retry") {
                Task {
                    await loadInsightCounts()
                }
            }
            .foregroundColor(ColorPalette.terracotta)
            .font(.system(size: 16, weight: .medium))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var categoryListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(RegulationCategory.allCases, id: \.self) { category in
                    NavigationLink(destination: RegulationCategoryView(
                        familyId: familyId,
                        category: category,
                        insightCount: insightCounts[category] ?? 0
                    )) {
                        RegulationCategoryCardContent(
                            category: category,
                            insightCount: insightCounts[category] ?? 0
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100) // Space for tab bar
        }
    }
    
    @MainActor
    private func loadInsightCounts() async {
        isLoading = true
        hasError = false
        
        do {
            insightCounts = try await ContextualInsightService.shared.getRegulationInsightCounts(familyId: familyId)
            print("✅ Loaded regulation insight counts: \(insightCounts)")
        } catch {
            print("❌ Failed to load regulation insight counts: \(error)")
            hasError = true
        }
        
        isLoading = false
    }
}

struct RegulationCategoryCardContent: View {
    let category: RegulationCategory
    let insightCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Icon and count row
            HStack(alignment: .top) {
                Image(systemName: category.iconName)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(ColorPalette.brightBlue)
                
                Spacer()
                
                if insightCount > 0 {
                    Text("\(insightCount)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ColorPalette.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(ColorPalette.terracotta)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            
            // Category name
            Text(category.parentFriendlyName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            
            // Insight count description
            if insightCount > 0 {
                Text("\(insightCount) insight\(insightCount == 1 ? "" : "s") collected")
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.white.opacity(0.7))
            } else {
                Text("No patterns identified yet")
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.white.opacity(0.5))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.21, green: 0.22, blue: 0.33))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - RegulationCategory Icon Extension

extension RegulationCategory {
    var iconName: String {
        switch self {
        case .core:
            return "heart.circle.fill"
        case .adhd:
            return "target"
        case .mildAutism:
            return "brain.head.profile"
        }
    }
}

#Preview {
    RegulationInsightsView(familyId: "preview-family-id")
}
