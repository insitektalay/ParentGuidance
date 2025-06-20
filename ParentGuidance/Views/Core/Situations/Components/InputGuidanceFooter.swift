import SwiftUI

struct InputGuidanceFooter: View {
    var body: some View {
        Text("The more details you share, the more tailored your guidance will be.")
            .font(.system(size: 12))
            .italic()
            .foregroundColor(ColorPalette.white.opacity(0.6))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
    }
}
