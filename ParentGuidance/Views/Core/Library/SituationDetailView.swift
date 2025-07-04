//
//  SituationDetailView.swift
//  ParentGuidance
//
//  Created by alex kerss on 04/07/2025.
//

import SwiftUI

struct SituationDetailView: View {
    let situation: Situation
    let guidance: [Guidance]
    let isLoadingGuidance: Bool
    let guidanceError: String?
    let onBack: () -> Void
    
    @State private var currentGuidancePage = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button and breadcrumb
            VStack(spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(ColorPalette.white.opacity(0.9))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Breadcrumb
                HStack {
                    Text("Library")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.5))
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.3))
                    
                    Text("Situation Details")
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Situation Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        // Title with emoji
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: SituationCard.getIconForEmoji(SituationCard.getEmojiForSituation(situation)))
                                .font(.system(size: 24))
                                .foregroundColor(ColorPalette.terracotta)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(situation.title)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(ColorPalette.white.opacity(0.9))
                                
                                Text(SituationCard.formatDate(situation.createdAt))
                                    .font(.system(size: 14))
                                    .foregroundColor(ColorPalette.white.opacity(0.6))
                            }
                            
                            Spacer()
                        }
                        
                        // Original Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Original Situation")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(ColorPalette.white.opacity(0.8))
                            
                            Text(situation.description)
                                .font(.system(size: 15))
                                .foregroundColor(ColorPalette.white.opacity(0.9))
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .background(Color(red: 0.21, green: 0.22, blue: 0.33))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 16)
                    
                    // Guidance Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("AI Guidance")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(ColorPalette.white.opacity(0.9))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        
                        if isLoadingGuidance {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .foregroundColor(ColorPalette.white.opacity(0.8))
                                
                                Text("Loading guidance...")
                                    .font(.system(size: 16))
                                    .foregroundColor(ColorPalette.white.opacity(0.7))
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                            
                        } else if let error = guidanceError {
                            VStack(spacing: 16) {
                                Text("No guidance available")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(ColorPalette.white.opacity(0.9))
                                
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundColor(ColorPalette.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                            
                        } else if guidance.isEmpty {
                            VStack(spacing: 16) {
                                Text("No guidance generated yet")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(ColorPalette.white.opacity(0.9))
                                
                                Text("This situation hasn't been processed for guidance yet.")
                                    .font(.system(size: 14))
                                    .foregroundColor(ColorPalette.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                            
                        } else {
                            // Display guidance content
                            if let firstGuidance = guidance.first {
                                let parsedGuidance = parseGuidanceContent(firstGuidance.content)
                                
                                if let guidance = parsedGuidance {
                                    GuidanceCardsView(guidance: guidance)
                                        .padding(.horizontal, 16)
                                } else {
                                    // Fallback: show raw guidance content
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Guidance Content")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(ColorPalette.white.opacity(0.8))
                                        
                                        Text(firstGuidance.content)
                                            .font(.system(size: 15))
                                            .foregroundColor(ColorPalette.white.opacity(0.9))
                                            .lineSpacing(4)
                                    }
                                    .padding(16)
                                    .background(Color(red: 0.21, green: 0.22, blue: 0.33))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .navigationBarHidden(true)
    }
    
    // MARK: - Helper Methods
    private func parseGuidanceContent(_ content: String) -> GuidanceResponse? {
        // Parse the stored guidance content back into structured format
        let title = extractSection(from: content, title: "Title") ?? "Guidance"
        let situation = extractSection(from: content, title: "Situation") ?? ""
        let analysis = extractSection(from: content, title: "Analysis") ?? ""
        let actionSteps = extractSection(from: content, title: "Action Steps") ?? ""
        let phrasesToTry = extractSection(from: content, title: "Phrases to Try") ?? ""
        let quickComebacks = extractSection(from: content, title: "Quick Comebacks") ?? ""
        let support = extractSection(from: content, title: "Support") ?? ""
        
        // Only return parsed guidance if we found meaningful content
        if !analysis.isEmpty || !actionSteps.isEmpty {
            return GuidanceResponse(
                title: title,
                situation: situation,
                analysis: analysis,
                actionSteps: actionSteps,
                phrasesToTry: phrasesToTry,
                quickComebacks: quickComebacks,
                support: support
            )
        }
        
        return nil
    }
    
    private func extractSection(from content: String, title: String) -> String? {
        // Convert section titles to bracket format
        let bracketTitle: String
        switch title {
        case "Title":
            bracketTitle = "TITLE"
        case "Situation":
            bracketTitle = "SITUATION"
        case "Analysis":
            bracketTitle = "ANALYSIS"
        case "Action Steps":
            bracketTitle = "ACTION STEPS"
        case "Phrases to Try":
            bracketTitle = "PHRASES TO TRY"
        case "Quick Comebacks":
            bracketTitle = "QUICK COMEBACKS"
        case "Support":
            bracketTitle = "SUPPORT"
        default:
            return nil
        }
        
        // Simple bracket-delimited pattern
        let pattern = "\\[\(NSRegularExpression.escapedPattern(for: bracketTitle))\\]\\s*\\n([\\s\\S]*?)(?=\\n\\s*\\[|$)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(content.startIndex..., in: content)
        
        if let match = regex?.firstMatch(in: content, options: [], range: range) {
            if let swiftRange = Range(match.range(at: 1), in: content) {
                return String(content[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return nil
    }
}

// MARK: - Guidance Cards Component
struct GuidanceCardsView: View {
    let guidance: GuidanceResponse
    @State private var currentPage = 0
    
    private var categories: [GuidanceCategory] {
        [
            GuidanceCategory(title: "Situation", content: guidance.situation),
            GuidanceCategory(title: "Analysis", content: guidance.analysis),
            GuidanceCategory(title: "Action Steps", content: guidance.actionSteps),
            GuidanceCategory(title: "Phrases to Try", content: guidance.phrasesToTry),
            GuidanceCategory(title: "Quick Comebacks", content: guidance.quickComebacks),
            GuidanceCategory(title: "Support", content: guidance.support)
        ].filter { !$0.content.isEmpty } // Only show non-empty sections
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if !categories.isEmpty {
                // Guidance cards
                TabView(selection: $currentPage) {
                    ForEach(0..<categories.count, id: \.self) { index in
                        GuidanceCard(
                            title: categories[index].title,
                            content: categories[index].content,
                            isActive: index == currentPage
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 400)
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<categories.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? ColorPalette.terracotta : ColorPalette.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
            }
        }
    }
}

#Preview {
    SituationDetailView(
        situation: Situation(
            familyId: "test",
            childId: nil,
            title: "Morning teeth brushing routine",
            description: "My 5-year-old refuses to brush their teeth every morning. It's becoming a daily battle and we're often late for school because of it."
        ),
        guidance: [],
        isLoadingGuidance: false,
        guidanceError: nil,
        onBack: {}
    )
}