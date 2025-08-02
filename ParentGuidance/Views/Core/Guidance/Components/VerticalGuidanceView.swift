import SwiftUI

struct VerticalGuidanceView: View {
    let guidance: GuidanceResponseProtocol
    var translationStatus: TranslationDisplayStatus? = nil
    var selectedLanguage: String? = nil
    var originalLanguage: String? = nil
    var canSwitchLanguage: Bool = false
    var onLanguageSwitch: (() -> Void)? = nil
    var isShowingOriginal: Bool = true
    var translationProgress: Double? = nil
    var onRetryTranslation: (() -> Void)? = nil
    var overallRecommendation: String? = nil
    var relevantInsights: [RelevantInsight] = []
    
    @Environment(\.dismiss) private var dismiss
    
    private var categories: [GuidanceCategory] {
        guidance.displaySections.map { section in
            GuidanceCategory(title: section.title, content: section.content)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with title
                VStack(spacing: 16) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(SemanticColors.primaryText)
                        }
                        
                        Spacer()
                        
                        Text(guidance.title)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(SemanticColors.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                        
                        // Invisible button for layout balance
                        Button(action: {}) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.clear)
                        }
                        .disabled(true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    
                    // Relevant insights (if any)
                    if !relevantInsights.isEmpty {
                        RelevantInsightsSection(insights: relevantInsights)
                            .padding(.horizontal, 16)
                    }
                    
                    // Overall recommendation (if available)
                    if let recommendation = overallRecommendation, !recommendation.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            // Header with icon
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(SemanticColors.accent)
                                
                                Text(String(localized: "guidance.overallRecommendation.title"))
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(SemanticColors.primaryText)
                                
                                Spacer()
                            }
                            
                            // Recommendation content
                            Text(recommendation)
                                .font(.system(size: 16))
                                .foregroundColor(SemanticColors.secondaryText)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(SemanticColors.accent.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(SemanticColors.accent.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 16)
                    }
                }
                
                // Vertical stack of guidance cards
                LazyVStack(spacing: 16) {
                    ForEach(0..<categories.count, id: \.self) { index in
                        GuidanceCard(
                            title: categories[index].title,
                            content: categories[index].content,
                            isActive: true, // All cards are active in vertical layout
                            translationStatus: translationStatus,
                            selectedLanguage: selectedLanguage,
                            originalLanguage: originalLanguage,
                            canSwitchLanguage: canSwitchLanguage,
                            onLanguageSwitch: onLanguageSwitch,
                            isShowingOriginal: isShowingOriginal,
                            translationProgress: translationProgress,
                            onRetryTranslation: onRetryTranslation
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 100) // Extra space for scrolling
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SemanticColors.primaryBackground)
        .navigationBarHidden(true)
    }
}

// MARK: - Preview Helper

extension RelevantInsight {
    static func preview(content: String) -> RelevantInsight {
        return RelevantInsight(
            situationId: "preview",
            guidanceId: "preview", 
            insightType: "contextual",
            insightId: "preview",
            insightContent: content
        )
    }
}

// MARK: - Preview

#Preview {
    VerticalGuidanceView(
        guidance: DynamicGuidanceResponse(
            title: "Morning Routine Help",
            sections: [
                GuidanceSection(title: "Understanding the Situation", content: "This is normal behavior for children this age. They're testing boundaries and asserting independence.", order: 1),
                GuidanceSection(title: "Immediate Steps", content: "1. Stay calm and patient\n2. Offer choices\n3. Create a routine", order: 2),
                GuidanceSection(title: "Building Connection", content: "Make it fun with songs or games. Let them pick their toothbrush color.", order: 3)
            ]
        ),
        overallRecommendation: "Focus on making brushing teeth a positive experience rather than a battle.",
        relevantInsights: [
            RelevantInsight.preview(content: "Your child responds well to choices and autonomy")
        ]
    )
}
