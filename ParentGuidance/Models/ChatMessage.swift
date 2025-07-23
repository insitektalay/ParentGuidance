//
//  ChatMessage.swift
//  ParentGuidance
//
//  Created by alex kerss on 23/07/2025.
//

import Foundation

enum ChatMessageSender {
    case user
    case ai
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let sender: ChatMessageSender
    let timestamp: Date
    
    init(text: String, sender: ChatMessageSender, timestamp: Date = Date()) {
        self.text = text
        self.sender = sender
        self.timestamp = timestamp
    }
}
