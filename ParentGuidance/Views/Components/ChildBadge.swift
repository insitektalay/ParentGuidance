import SwiftUI

struct ChildBadge: View {
    let childName: String
    
    var body: some View {
        Text(childName)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(SemanticColors.primaryText) // Always white text on accent background
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(SemanticColors.accent.opacity(0.9))
            .clipShape(Capsule())
    }
}