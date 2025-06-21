import SwiftUI

struct InputGuidanceFooter: View {
    var body: some View {
        HStack {
            Text("More details mean better guidance.")
                .font(.system(size: 12))
                .italic()
                .foregroundColor(ColorPalette.white.opacity(0.6))
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}
