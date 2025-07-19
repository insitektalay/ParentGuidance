import SwiftUI

struct SituationGuidanceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var categories: [GuidanceCategory] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @ObservedObject private var guidanceStructureSettings = GuidanceStructureSettings.shared
    let situation: Situation?
    
    init(situation: Situation? = nil) {
        self.situation = situation
    }
    
    // Fallback categories if no situation is provided
    private let fallbackCategories = [
        GuidanceCategory(
            title: "Situation",
            content: "It sounds like Alex was deeply engaged in his Lego play when you let him know it was time to brush his teeth before bed. He reacted strongly by throwing the Lego pieces, yelling that he hates brushing his teeth, and then shutting himself in his room, clearly showing big feelings about the transition."
        ),
        GuidanceCategory(
            title: "Analysis", 
            content: "This moment likely reflects Alex shifting suddenly from the Green Zone of regulation—where he felt calm and focused during play—to the Red Zone, where he became explosive and overwhelmed by frustration. Sudden transitions, especially from enjoyable activities to less preferred tasks like brushing teeth, can be particularly challenging for kids. Recognizing which zone Alex was in before, during, and after his reaction can help you support him in regulating those big emotions and returning to a calmer state."
        ),
        GuidanceCategory(
            title: "Action Steps",
            content: """
1. Allow Alex some space to cool down before approaching him—he's likely in the Red Zone and not ready for problem-solving just yet.

2. Check in with your own zone; maintaining a calm presence can help model regulation for Alex.

3. Once Alex has settled, gently check in with him about how he's feeling using zone language ("Do you think you were in the Red Zone when you ran to your room?").

4. Debrief together about what helped (or could help) when moving from fun activities to bedtime routines. Encourage Alex to notice his zones before transitions.

5. Build in a gentle zone-check or warning before future transitions ("I see you're in the Green Zone having fun with your Legos. In five minutes, it'll be time to start our bedtime routine. Let's think about what zone we'll need to be in for that.").

6. Consider creating a visual chart to help Alex identify when he's in the Green, Yellow, Red, or Blue Zone, and co-create a list of regulation strategies for each zone. This approach uses your Zones of Regulation to guide the response strategy.
"""
        ),
        GuidanceCategory(
            title: "Phrases to Try",
            content: """
"It looked like you went into the Red Zone when I asked you to stop playing. That's a lot of big feelings."

"Let's take a few deep breaths together and check our zones. Are you ready to talk, or do you need a few more minutes to get back to your Green Zone?"

"I know transitions can be hard. Can we think of one thing that would help make moving from playing to brushing teeth a little easier next time?"

"When you feel like you're getting frustrated or moving into the Yellow Zone, what can we do to help you get back to Green before we start something new?" This approach uses your Zones of Regulation to guide the response strategy.
"""
        ),
        GuidanceCategory(
            title: "Quick Comebacks",
            content: """
If Alex says, "I hate brushing teeth!" you might say, "It sounds like your feelings about brushing teeth have put you deep in the Red Zone. Let's find a way to get back to Green before we head to the bathroom."

If he protests, "I don't want to!" you might calmly respond, "I understand you don't want to—sometimes our bodies move into the Yellow or Red Zone when we have to stop something we like. How can I help you move back toward Green so brushing teeth isn't so tough?" This approach uses your Zones of Regulation to guide the response strategy.
"""
        ),
        GuidanceCategory(
            title: "Support",
            content: "Transitions are often a common trigger for kids experiencing big emotions, especially when moving away from something they enjoy. By using zone language consistently and proactively checking in about what zone Alex is in, you're helping him build self-awareness and emotional regulation skills that will support him far beyond bedtime routines. Every time you help him name and navigate his feelings, you're planting seeds for more peaceful transitions in the future. This approach uses your Zones of Regulation to guide the response strategy."
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                // Loading state
                VStack {
                    ProgressView()
                        .tint(ColorPalette.terracotta)
                    Text("Loading guidance...")
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ColorPalette.navy)
            } else if let error = errorMessage {
                // Error state
                VStack {
                    Text("Unable to load guidance")
                        .font(.system(size: 18))
                        .foregroundColor(ColorPalette.white)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                        .padding(.top, 4)
                    
                    Button("Try Again") {
                        loadGuidance()
                    }
                    .foregroundColor(ColorPalette.terracotta)
                    .padding(.top, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ColorPalette.navy)
            } else {
                // Content state
                guidanceContent
            }
        }
        .task {
            loadGuidance()
        }
    }
    
    private var guidanceContent: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack(alignment: .center, spacing: 12) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)
            
            // Title
            HStack {
                Text(situation?.title ?? "Situation Guidance")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(ColorPalette.white.opacity(0.9))
                    .padding(.horizontal, 16)
                
                Spacer()
            }
            .padding(.bottom, 16)
            
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
            .padding(.horizontal, 16)
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<categories.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? ColorPalette.terracotta : ColorPalette.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 10) // Space for tab bar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .navigationBarHidden(true)
    }
    
    // MARK: - Guidance Loading
    
    private func loadGuidance() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                if let situation = situation {
                    print("📋 Loading guidance for situation: \(situation.id)")
                    let guidanceEntries = try await ConversationService.shared.getGuidanceForSituation(situationId: situation.id)
                    
                    await MainActor.run {
                        if guidanceEntries.isEmpty {
                            print("⚠️ No guidance found for situation, using fallback")
                            self.categories = fallbackCategories
                        } else {
                            print("✅ Parsing \(guidanceEntries.count) guidance entries")
                            self.categories = parseGuidanceContent(from: guidanceEntries)
                        }
                        self.isLoading = false
                    }
                } else {
                    print("ℹ️ No situation provided, using fallback categories")
                    await MainActor.run {
                        self.categories = fallbackCategories
                        self.isLoading = false
                    }
                }
            } catch {
                print("❌ Error loading guidance: \(error)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.categories = fallbackCategories // Fallback on error
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Guidance Parsing
    
    private func parseGuidanceContent(from guidanceEntries: [Guidance]) -> [GuidanceCategory] {
        // Combine all guidance content (in case there are multiple entries)
        let fullContent = guidanceEntries.map { $0.content }.joined(separator: "\n\n")
        
        print("🔍 [DEBUG] SituationGuidanceView: Parsing guidance content")
        print("   - Settings says use dynamic: \(guidanceStructureSettings.isUsingDynamicStructure)")
        print("   - Content length: \(fullContent.count) characters")
        
        // Parse based on user preference (same logic as NewSituationView)
        if guidanceStructureSettings.isUsingDynamicStructure {
            print("🔄 [DEBUG] SituationGuidanceView: Using DYNAMIC parsing")
            // Try dynamic parser first
            if let dynamicResponse = DynamicGuidanceParser.shared.parseWithFallback(fullContent) {
                print("✅ [DEBUG] Dynamic parsing SUCCESS - \(dynamicResponse.displaySections.count) sections")
                return dynamicResponse.displaySections.map { section in
                    GuidanceCategory(title: section.title, content: section.content)
                }
            } else {
                print("❌ [DEBUG] Dynamic parsing FAILED, falling back to fixed")
                return parseFixedGuidanceContent(from: fullContent)
            }
        } else {
            print("🔄 [DEBUG] SituationGuidanceView: Using FIXED parsing")
            return parseFixedGuidanceContent(from: fullContent)
        }
    }
    
    private func parseFixedGuidanceContent(from fullContent: String) -> [GuidanceCategory] {
        // Extract the 6 fixed categories
        return [
            GuidanceCategory(
                title: "Situation",
                content: extractSection(from: fullContent, title: "Situation") ?? "No situation description available."
            ),
            GuidanceCategory(
                title: "Analysis",
                content: extractSection(from: fullContent, title: "Analysis") ?? "No analysis available."
            ),
            GuidanceCategory(
                title: "Action Steps",
                content: extractSection(from: fullContent, title: "Action Steps") ?? "No action steps available."
            ),
            GuidanceCategory(
                title: "Phrases to Try",
                content: extractSection(from: fullContent, title: "Phrases to Try") ?? "No phrases available."
            ),
            GuidanceCategory(
                title: "Quick Comebacks",
                content: extractSection(from: fullContent, title: "Quick Comebacks") ?? "No quick comebacks available."
            ),
            GuidanceCategory(
                title: "Support",
                content: extractSection(from: fullContent, title: "Support") ?? "No support information available."
            )
        ]
    }
    
    private func extractSection(from content: String, title: String) -> String? {
        // Convert section titles to bracket format
        let bracketTitle: String
        switch title {
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
            print("❌ Unknown section title: \(title)")
            return nil
        }
        
        // Simple bracket-delimited pattern: [SECTION]\nContent until next [SECTION] or end
        let pattern = "\\[\(NSRegularExpression.escapedPattern(for: bracketTitle))\\]\\s*\\n([\\s\\S]*?)(?=\\n\\s*\\[|$)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(content.startIndex..., in: content)
        
        if let match = regex?.firstMatch(in: content, options: [], range: range) {
            let matchRange = Range(match.range(at: 1), in: content)!
            let extracted = String(content[matchRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            return extracted.isEmpty ? nil : extracted
        }
        
        return nil
    }
}

struct GuidanceCategory {
    let title: String
    let content: String
}

#Preview {
    NavigationView {
        SituationGuidanceView()
    }
}
