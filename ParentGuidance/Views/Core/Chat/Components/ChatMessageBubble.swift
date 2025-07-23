//
//  ChatMessageBubble.swift
//  ParentGuidance
//
//  Created by alex kerss on 23/07/2025.
//

import SwiftUI

struct ChatMessageBubble: View {
    let message: ChatMessage
    let isStreaming: Bool
    
    init(message: ChatMessage, isStreaming: Bool = false) {
        self.message = message
        self.isStreaming = isStreaming
    }
    
    var body: some View {
        Group {
            switch message.sender {
            case .user:
                userMessageBubble
            case .ai:
                aiMessageBubble
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    // MARK: - User Message Bubble
    
    private var userMessageBubble: some View {
        HStack {
            Spacer()
            
            Text(message.text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(ColorPalette.terracotta)
                .cornerRadius(18)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
        }
    }
    
    // MARK: - AI Message Bubble
    
    private var aiMessageBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Full-width AI response
            HStack {
                Text(message.text)
                    .font(.system(size: 16))
                    .foregroundColor(ColorPalette.white.opacity(0.9))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer(minLength: 0)
            }
            
            // Streaming indicator
            if isStreaming {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(ColorPalette.terracotta.opacity(0.6))
                            .frame(width: 6, height: 6)
                            .scaleEffect(isStreaming ? 1.0 : 0.6)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: isStreaming
                            )
                    }
                }
                .padding(.leading, 4)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
