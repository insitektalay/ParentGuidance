import SwiftUI

// PreferenceKey to measure text height
struct TextViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 44
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ChatInputBar: View {
    @Binding var text: String
    var onSend: () -> Void
    var onMic: () -> Void
    var isRecording: Bool = false
    var isTranscribing: Bool = false
    var isSending: Bool = false

    @FocusState private var isTextEditorFocused: Bool
    @State private var measuredHeight: CGFloat = 44

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Mic button
            Button(action: {
                if !isTranscribing && !isSending {
                    onMic()
                }
            }) {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .font(.system(size: 22))
                    .foregroundColor(isRecording ? ColorPalette.terracotta : ColorPalette.white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(ColorPalette.white.opacity(0.1))
                    )
            }
            .disabled(isTranscribing || isSending)

            // Growing text input
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(String(localized: "chat.input.placeholder"))
                        .foregroundColor(ColorPalette.white.opacity(0.5))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                }

                TextEditor(text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(ColorPalette.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(height: measuredHeight)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                    .focused($isTextEditorFocused)
                    .background(
                        Text(text)
                            .font(.system(size: 16))
                            .lineLimit(nil)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(key: TextViewHeightKey.self, value: geo.size.height)
                                }
                            )
                            .hidden()
                    )
                    .onPreferenceChange(TextViewHeightKey.self) { height in
                        let clamped = min(max(height, 24), 120)
                        if measuredHeight != clamped {
                            measuredHeight = clamped
                        }
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(ColorPalette.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        isTextEditorFocused ? ColorPalette.terracotta.opacity(0.5) : Color.clear,
                        lineWidth: 1.5
                    )
            )

            // Send button
            Button(action: {
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending {
                    onSend()
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending
                            ? ColorPalette.white.opacity(0.3)
                            : ColorPalette.terracotta
                    )
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(ColorPalette.navy)
    }
}
