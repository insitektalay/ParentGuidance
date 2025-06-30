import SwiftUI

struct GuidanceCard: View {
    let title: String
    let content: String
    let isActive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card container
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Category title
                    Text(title)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    // Content text
                    Text(content)
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 400)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isActive ? ColorPalette.terracotta.opacity(0.3) : ColorPalette.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
    }
}

#Preview {
    HStack(spacing: 16) {
        GuidanceCard(
            title: "Analysis",
            content: "This moment likely reflects Alex shifting suddenly from the Green Zone of regulation—where he felt calm and focused during play—to the Red Zone, where he became explosive and overwhelmed by frustration.",
            isActive: true
        )
        
        GuidanceCard(
            title: "Support",
            content: "Transitions are often a common trigger for kids experiencing big emotions. By using zone language consistently, you're helping him build self-awareness.",
            isActive: false
        )
    }
    .padding()
    .background(ColorPalette.navy)
}