import SwiftUI

struct SendButton: View {
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(isEnabled ? ColorPalette.white : ColorPalette.white.opacity(0.3))
                .frame(width: 56, height: 56)
                .background(isEnabled ? ColorPalette.terracotta : ColorPalette.white.opacity(0.1))
                .clipShape(Circle())
        }
        .disabled(!isEnabled)
        .accessibilityLabel("Send message")
        .accessibilityHint(isEnabled ? "Double tap to send your message" : "Enter text to enable sending")
    }
}
