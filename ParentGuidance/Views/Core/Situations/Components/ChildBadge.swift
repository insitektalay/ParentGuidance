import SwiftUI

struct ChildBadge: View {
    let childName: String
    
    var body: some View {
        Text(childName)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(ColorPalette.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(ColorPalette.terracotta.opacity(0.9))
            .clipShape(Capsule())
    }
}
