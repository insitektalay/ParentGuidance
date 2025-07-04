import SwiftUI

struct SituationGuidanceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    let situation: Situation?
    
    init(situation: Situation? = nil) {
        self.situation = situation
    }
    
    private let categories = [
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
                Text("Morning Tooth Brushing")
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
            .padding(.bottom, 100) // Space for tab bar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .navigationBarHidden(true)
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