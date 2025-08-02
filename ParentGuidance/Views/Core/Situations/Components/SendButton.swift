import SwiftUI

struct SendButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(isEnabled ? SemanticColors.primaryText : SemanticColors.tertiaryText)
                .frame(width: 56, height: 56)
                .background(isEnabled ? SemanticColors.accent : SemanticColors.tertiaryText.opacity(0.3))
                .clipShape(Circle())
                .if(colorScheme == .light && isEnabled) { view in
                    view.cardShadow()
                }
        }
        .disabled(!isEnabled)
        .accessibilityLabel(String(localized: "situation.input.send"))
        .accessibilityHint(isEnabled ? String(localized: "situation.input.send.hint") : String(localized: "situation.input.empty.hint"))
    }
}
