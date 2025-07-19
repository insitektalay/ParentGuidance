import SwiftUI

struct GuidanceCard: View {
    let title: String
    let content: String
    let isActive: Bool
    var translationStatus: TranslationDisplayStatus? = nil
    var selectedLanguage: String? = nil
    var canSwitchLanguage: Bool = false
    var onLanguageSwitch: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card container
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Category title with language indicator
                    HStack {
                        Text(title)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(ColorPalette.white.opacity(0.9))
                        
                        Spacer()
                        
                        // Translation status and language indicator
                        HStack(spacing: 8) {
                            if let status = translationStatus {
                                translationStatusIndicator(status: status)
                            }
                            
                            if let language = selectedLanguage, language != "en" {
                                languageIndicator(language: language)
                            }
                            
                            if canSwitchLanguage, let onLanguageSwitch = onLanguageSwitch {
                                Button(action: onLanguageSwitch) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ColorPalette.white.opacity(0.7))
                                }
                            }
                        }
                    }
                    
                    // Content text
                    Text(createAttributedContent(from: content))
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 580)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isActive ? ColorPalette.terracotta.opacity(0.3) : ColorPalette.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
    }
    
    // MARK: - Helper Functions
    
    private func createAttributedContent(from content: String) -> AttributedString {
        var attributedString = AttributedString(content)
        
        // Split content into lines
        let lines = content.components(separatedBy: .newlines)
        var currentPosition = 0
        
        for (lineIndex, line) in lines.enumerated() {
            // Check if this line is a bullet point
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let isBulletPoint = trimmedLine.hasPrefix("•") || 
                              trimmedLine.hasPrefix("-") ||
                              (trimmedLine.count > 0 && trimmedLine.first?.isNumber == true && trimmedLine.contains("."))
            
            // Calculate the line content and its length
            let lineContent = lineIndex < lines.count - 1 ? line + "\n" : line
            let lineLength = lineContent.utf16.count
            
            // Create the range for this line
            let startIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: currentPosition)
            let endIndex = attributedString.index(startIndex, offsetByCharacters: lineLength)
            let lineRange = startIndex..<endIndex
            
            if isBulletPoint && lineIndex < lines.count - 1 {
                // Create paragraph style with extra spacing after bullet points
                var paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.paragraphSpacing = 12.0 // Extra space after bullet points
                paragraphStyle.lineSpacing = 4.0 // Normal line spacing within bullet points
                
                // Apply the paragraph style to this line
                attributedString[lineRange].paragraphStyle = paragraphStyle
            } else {
                // For non-bullet lines, apply normal spacing
                var paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4.0 // Normal line spacing
                paragraphStyle.paragraphSpacing = 0.0 // No extra spacing for regular text
                
                attributedString[lineRange].paragraphStyle = paragraphStyle
            }
            
            // Move to the next line
            currentPosition += lineLength
        }
        
        return attributedString
    }
    
    // MARK: - Translation Status and Language Indicators
    
    @ViewBuilder
    private func translationStatusIndicator(status: TranslationDisplayStatus) -> some View {
        let (icon, color) = getStatusIndicator(for: status)
        
        Image(systemName: icon)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(color)
            .help(getStatusDescription(for: status))
    }
    
    @ViewBuilder
    private func languageIndicator(language: String) -> some View {
        Text(language.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(ColorPalette.white.opacity(0.8))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(ColorPalette.terracotta.opacity(0.6))
            .cornerRadius(4)
    }
    
    private func getStatusIndicator(for status: TranslationDisplayStatus) -> (String, Color) {
        switch status {
        case .completed:
            return ("checkmark.circle.fill", .green)
        case .pending:
            return ("clock.fill", .orange)
        case .inProgress:
            return ("arrow.clockwise", .blue)
        case .failed:
            return ("exclamationmark.triangle.fill", .red)
        case .retrying:
            return ("arrow.clockwise", .yellow)
        case .notNeeded:
            return ("", .clear)
        }
    }
    
    private func getStatusDescription(for status: TranslationDisplayStatus) -> String {
        switch status {
        case .completed:
            return "Translation completed"
        case .pending:
            return "Translation pending"
        case .inProgress:
            return "Translation in progress"
        case .failed:
            return "Translation failed"
        case .retrying:
            return "Translation retrying"
        case .notNeeded:
            return "Translation not needed"
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        GuidanceCard(
            title: "Analysis",
            content: "This moment likely reflects Alex shifting suddenly from the Green Zone of regulation—where he felt calm and focused during play—to the Red Zone, where he became explosive and overwhelmed by frustration.",
            isActive: true
        )
        
        GuidanceCard(
            title: "Support",
            content: "Transitions are often a common trigger for kids experiencing big emotions. By using zone language consistently, you're helping him build self-awareness.",
            isActive: false
        )
    }
    .padding()
    .background(ColorPalette.navy)
}
