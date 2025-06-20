import SwiftUI

struct MicButton: View {
    @Binding var isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "mic.fill")
                .font(.system(size: 24))
                .foregroundColor(ColorPalette.white)
                .frame(width: 56, height: 56)
                .background(isRecording ? Color.red : ColorPalette.terracotta)
                .clipShape(Circle())
        }
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
        .accessibilityHint("Double tap to toggle voice recording")
    }
}
