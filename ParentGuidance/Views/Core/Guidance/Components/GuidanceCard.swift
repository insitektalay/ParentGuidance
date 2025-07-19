import SwiftUI

struct GuidanceCard: View {
    let title: String
    let content: String
    let isActive: Bool
    var translationStatus: TranslationDisplayStatus? = nil
    var selectedLanguage: String? = nil
    var originalLanguage: String? = nil
    var canSwitchLanguage: Bool = false
    var onLanguageSwitch: (() -> Void)? = nil
    var isShowingOriginal: Bool = true
    var translationProgress: Double? = nil
    var onRetryTranslation: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card container
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Category title with enhanced language controls
                    HStack {
                        Text(title)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(ColorPalette.white.opacity(0.9))
                        
                        Spacer()
                        
                        // Enhanced translation status and language controls
                        HStack(spacing: 8) {
                            // Translation progress indicator
                            if let progress = translationProgress {
                                translationProgressIndicator(progress: progress)
                            }
                            
                            // Translation status indicator
                            if let status = translationStatus {
                                translationStatusIndicator(status: status)
                            }
                            
                            // Current language indicator
                            if let language = selectedLanguage {
                                languageIndicator(language: language, isOriginal: isShowingOriginal)
                            }
                            
                            // Language toggle button (enhanced)
                            if canSwitchLanguage, let onLanguageSwitch = onLanguageSwitch {
                                languageToggleButton(onSwitch: onLanguageSwitch)
                            }
                        }
                    }
                    
                    // Language toggle banner (for prominent display)
                    if canSwitchLanguage && !isShowingOriginal {
                        languageToggleBanner
                    }
                    
                    // Translation error banner
                    if let status = translationStatus, status == .failed {
                        translationErrorBanner
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
    
    // MARK: - Enhanced Translation UI Components
    
    @ViewBuilder
    private func translationProgressIndicator(progress: Double) -> some View {
        HStack(spacing: 4) {
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: ColorPalette.brightBlue))
                .frame(width: 30, height: 3)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.7))
        }
    }
    
    @ViewBuilder
    private func languageToggleButton(onSwitch: @escaping () -> Void) -> some View {
        Button(action: onSwitch) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 12, weight: .medium))
                
                Text(isShowingOriginal ? "Translate" : "Original")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(ColorPalette.white.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(ColorPalette.white.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var languageToggleBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "translate")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorPalette.brightBlue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "guidance.translation.viewingTranslated"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ColorPalette.white.opacity(0.9))
                
                Text(String(localized: "guidance.translation.tapToViewOriginal"))
                    .font(.system(size: 10))
                    .foregroundColor(ColorPalette.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(String(localized: "guidance.translation.viewOriginal")) {
                onLanguageSwitch?()
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(ColorPalette.brightBlue)
        }
        .padding(12)
        .background(ColorPalette.brightBlue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var translationErrorBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "guidance.translation.error.title"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ColorPalette.white.opacity(0.9))
                
                Text(String(localized: "guidance.translation.error.description"))
                    .font(.system(size: 10))
                    .foregroundColor(ColorPalette.white.opacity(0.7))
            }
            
            Spacer()
            
            if let onRetry = onRetryTranslation {
                Button(String(localized: "guidance.translation.retry")) {
                    onRetry()
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.orange)
            }
        }
        .padding(12)
        .background(.orange.opacity(0.1))
        .cornerRadius(8)
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
    private func languageIndicator(language: String, isOriginal: Bool = true) -> some View {
        HStack(spacing: 2) {
            if !isOriginal {
                Image(systemName: "translate")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(ColorPalette.white.opacity(0.8))
            }
            
            Text(language.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(ColorPalette.white.opacity(0.8))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(isOriginal ? ColorPalette.terracotta.opacity(0.6) : ColorPalette.brightBlue.opacity(0.6))
        .cornerRadius(4)
    }
    
    private func getStatusIndicator(for status: TranslationDisplayStatus) -> (String, Color) {
        switch status {
        case .completed:
            return ("checkmark.circle.fill", .green)
        case .pending:
            return ("clock.fill", .orange)
        case .inProgress:
            return ("arrow.clockwise", ColorPalette.brightBlue)
        case .failed:
            return ("exclamationmark.triangle.fill", .red)
        case .retrying:
            return ("arrow.2.clockwise", .yellow)
        case .notNeeded:
            return ("", .clear)
        }
    }
    
    private func getStatusDescription(for status: TranslationDisplayStatus) -> String {
        switch status {
        case .completed:
            return String(localized: "guidance.translation.status.completed")
        case .pending:
            return String(localized: "guidance.translation.status.pending")
        case .inProgress:
            return String(localized: "guidance.translation.status.inProgress")
        case .failed:
            return String(localized: "guidance.translation.status.failed")
        case .retrying:
            return String(localized: "guidance.translation.status.retrying")
        case .notNeeded:
            return String(localized: "guidance.translation.status.notNeeded")
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
