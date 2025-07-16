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
    @State private var showCopyConfirmation = false
    @ObservedObject private var guidanceStructureSettings = GuidanceStructureSettings.shared
    
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
                    .padding(.horizontal, 16)
                    
                    // Guidance Section (moved above situation)
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
                                let fullContent = guidance.map { $0.content }.joined(separator: "\n\n")
                                let parsedCategories = parseGuidanceContent(fullContent)
                                
                                if let categories = parsedCategories, !categories.isEmpty {
                                    // Use the same card system as SituationGuidanceView
                                    VStack(spacing: 16) {
                                        // Guidance cards
                                        TabView(selection: $currentGuidancePage) {
                                            ForEach(0..<categories.count, id: \.self) { index in
                                                GuidanceCard(
                                                    title: categories[index].title,
                                                    content: categories[index].content,
                                                    isActive: index == currentGuidancePage
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
                                                    .fill(index == currentGuidancePage ? ColorPalette.terracotta : ColorPalette.white.opacity(0.3))
                                                    .frame(width: 8, height: 8)
                                                    .animation(.easeInOut(duration: 0.2), value: currentGuidancePage)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                } else {
                                    // Fallback: show raw guidance content in card format
                                    VStack(spacing: 16) {
                                        GuidanceCard(
                                            title: "Guidance Content",
                                            content: firstGuidance.content,
                                            isActive: true
                                        )
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                    
                    // Original Situation Section (moved below guidance)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Original Situation")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(ColorPalette.white.opacity(0.8))
                            
                            Spacer()
                            
                            Button(action: {
                                copyToClipboard(situation.description)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 12))
                                    Text("Copy")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(ColorPalette.terracotta)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(ColorPalette.terracotta.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                        
                        Text(situation.description)
                            .font(.system(size: 15))
                            .foregroundColor(ColorPalette.white.opacity(0.9))
                            .lineSpacing(4)
                            .textSelection(.enabled)
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
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .navigationBarHidden(true)
        .overlay(
            // Copy confirmation overlay
            VStack {
                if showCopyConfirmation {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                        
                        Text("Copied to clipboard")
                            .font(.system(size: 14))
                            .foregroundColor(ColorPalette.white)
                    }
                    .padding(16)
                    .background(ColorPalette.navy.opacity(0.9))
                    .cornerRadius(12)
                    .shadow(radius: 8)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showCopyConfirmation)
        )
    }
    
    // MARK: - Helper Methods
    private func parseGuidanceContent(_ content: String) -> [GuidanceCategory]? {
        print("🔍 [DEBUG] SituationDetailView: Parsing guidance content")
        print("   - Settings says use dynamic: \(guidanceStructureSettings.isUsingDynamicStructure)")
        print("   - Content length: \(content.count) characters")
        
        // Parse based on user preference (same logic as SituationGuidanceView)
        if guidanceStructureSettings.isUsingDynamicStructure {
            print("🔄 [DEBUG] SituationDetailView: Using DYNAMIC parsing")
            // Try dynamic parser first
            if let dynamicResponse = DynamicGuidanceParser.shared.parseWithFallback(content) {
                print("✅ [DEBUG] Dynamic parsing SUCCESS - \(dynamicResponse.displaySections.count) sections")
                return dynamicResponse.displaySections.map { section in
                    GuidanceCategory(title: section.title, content: section.content)
                }
            } else {
                print("❌ [DEBUG] Dynamic parsing FAILED, falling back to fixed")
                return parseFixedGuidanceContent(from: content)
            }
        } else {
            print("🔄 [DEBUG] SituationDetailView: Using FIXED parsing")
            return parseFixedGuidanceContent(from: content)
        }
    }
    
    private func parseFixedGuidanceContent(from content: String) -> [GuidanceCategory] {
        // Extract the 6 fixed categories
        return [
            GuidanceCategory(
                title: "Situation",
                content: extractSection(from: content, title: "Situation") ?? "No situation description available."
            ),
            GuidanceCategory(
                title: "Analysis",
                content: extractSection(from: content, title: "Analysis") ?? "No analysis available."
            ),
            GuidanceCategory(
                title: "Action Steps",
                content: extractSection(from: content, title: "Action Steps") ?? "No action steps available."
            ),
            GuidanceCategory(
                title: "Phrases to Try",
                content: extractSection(from: content, title: "Phrases to Try") ?? "No phrases available."
            ),
            GuidanceCategory(
                title: "Quick Comebacks",
                content: extractSection(from: content, title: "Quick Comebacks") ?? "No quick comebacks available."
            ),
            GuidanceCategory(
                title: "Support",
                content: extractSection(from: content, title: "Support") ?? "No support information available."
            )
        ].filter { !$0.content.isEmpty && $0.content != "No \($0.title.lowercased()) available." }
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
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Show brief confirmation
        showCopyConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopyConfirmation = false
        }
    }
}


#Preview {
    SituationDetailView(
        situation: Situation(
            familyId: "test",
            childId: nil,
            title: "Morning teeth brushing routine",
            description: "My 5-year-old refuses to brush their teeth every morning. It's becoming a daily battle and we're often late for school because of it.",
            category: "Routine-Building",
            isIncident: true
        ),
        guidance: [],
        isLoadingGuidance: false,
        guidanceError: nil,
        onBack: {}
    )
}