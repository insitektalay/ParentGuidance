import SwiftUI

struct InputGuidanceFooter: View {
    var body: some View {
        HStack {
            Text("More details mean better guidance.")
                .font(.system(size: 12))
                .italic()
                .foregroundColor(SemanticColors.tertiaryText)
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}
