//
//  LanguageOptionRow.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct LanguageOptionRow: View {
    let languageCode: String
    let languageName: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Language flag emoji (simplified representation)
                Text(flagEmoji(for: languageCode))
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(languageName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                    
                    Text(languageCode.uppercased())
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ColorPalette.brightBlue)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(ColorPalette.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? ColorPalette.brightBlue.opacity(0.1) : ColorPalette.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? ColorPalette.brightBlue.opacity(0.3) : ColorPalette.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func flagEmoji(for languageCode: String) -> String {
        // Simple flag emoji mapping - this could be expanded
        switch languageCode {
        case "en": return "🇺🇸"
        case "es": return "🇪🇸"
        case "fr": return "🇫🇷"
        case "de": return "🇩🇪"
        case "it": return "🇮🇹"
        case "pt": return "🇵🇹"
        case "ru": return "🇷🇺"
        case "zh": return "🇨🇳"
        case "ja": return "🇯🇵"
        case "ko": return "🇰🇷"
        case "ar": return "🇸🇦"
        case "hi": return "🇮🇳"
        case "nl": return "🇳🇱"
        case "sv": return "🇸🇪"
        case "no": return "🇳🇴"
        case "da": return "🇩🇰"
        case "fi": return "🇫🇮"
        case "pl": return "🇵🇱"
        case "cs": return "🇨🇿"
        case "hu": return "🇭🇺"
        case "tr": return "🇹🇷"
        case "he": return "🇮🇱"
        case "th": return "🇹🇭"
        case "vi": return "🇻🇳"
        case "uk": return "🇺🇦"
        case "bg": return "🇧🇬"
        case "hr": return "🇭🇷"
        case "sk": return "🇸🇰"
        case "sl": return "🇸🇮"
        case "et": return "🇪🇪"
        case "lv": return "🇱🇻"
        case "lt": return "🇱🇹"
        case "ro": return "🇷🇴"
        case "el": return "🇬🇷"
        case "is": return "🇮🇸"
        case "mt": return "🇲🇹"
        case "ga": return "🇮🇪"
        case "cy": return "🏴󠁧󠁢󠁷󠁬󠁳󠁿"
        case "ca": return "🏴󠁥󠁳󠁣󠁴󠁿"
        case "ur": return "🇵🇰"
        case "fa": return "🇮🇷"
        case "sw": return "🇰🇪"
        case "ms": return "🇲🇾"
        case "id": return "🇮🇩"
        case "tl": return "🇵🇭"
        default: return "🌐"
        }
    }
}
