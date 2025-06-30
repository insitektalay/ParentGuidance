import SwiftUI

struct FoundationToolCard: View {
    let onViewTools: () -> Void
    let onManage: () -> Void
    
    init(
        onViewTools: @escaping () -> Void = {},
        onManage: @escaping () -> Void = {}
    ) {
        self.onViewTools = onViewTools
        self.onManage = onManage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "target")
                    .font(.system(size: 20))
                    .foregroundColor(ColorPalette.white)
                
                Text("Zones of Regulation")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ColorPalette.white)
                
                Spacer()
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onViewTools) {
                    Text("View tools")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(ColorPalette.terracotta)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: onManage) {
                    Text("Manage")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.terracotta)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ColorPalette.terracotta, lineWidth: 1)
                        )
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(red: 0.21, green: 0.22, blue: 0.33)) // #363853 equivalent
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    FoundationToolCard()
        .padding()
        .background(ColorPalette.navy)
}