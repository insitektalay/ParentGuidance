//
//  DynamicGuidanceParser.swift
//  ParentGuidance
//
//  Created by alex kerss on 16/07/2025.
//

import Foundation

class DynamicGuidanceParser {
    static let shared = DynamicGuidanceParser()
    
    private init() {}
    
    func parseDynamicGuidanceResponse(_ content: String) -> DynamicGuidanceResponse? {
        print("🔍 Dynamic Parser: Parsing content with dynamic section extraction...")
        print("📄 Full content for debugging:")
        print("================== START CONTENT ==================")
        print(content)
        print("================== END CONTENT ==================")
        print("📄 Content preview: \(String(content.prefix(200)))...")
        
        // Extract title first
        guard let title = extractTitle(from: content) else {
            print("❌ Dynamic Parser: Failed to extract title")
            return nil
        }
        
        // Extract all dynamic sections
        let sections = extractAllSections(from: content, excludingTitle: title)
        
        // Validate section count (3-8 as per requirements)
        guard sections.count >= 3 && sections.count <= 8 else {
            print("❌ Dynamic Parser: Invalid section count: \(sections.count). Expected 3-8 sections.")
            return nil
        }
        
        print("✅ Dynamic Parser: Successfully extracted \(sections.count) sections")
        for section in sections {
            print("   Section \(section.order): \(section.title)")
        }
        
        return DynamicGuidanceResponse(title: title, sections: sections)
    }
    
    private func extractTitle(from content: String) -> String? {
        print("🔍 [DynamicParser] ===== TITLE EXTRACTION DEBUG =====")
        print("🔍 [DynamicParser] Content length: \(content.count) characters")
        print("🔍 [DynamicParser] Content preview (first 500 chars):")
        print("🔍 [DynamicParser] \(String(content.prefix(500)))")
        print("🔍 [DynamicParser] =====================================")
        
        // Try multiple patterns for [TITLE] section extraction
        // Based on promptTemplates.ts: "[TITLE]  \nA concise, parent-friendly title here"
        let patterns = [
            "\\[TITLE\\]\\s*\\n([^\\[\\n]+)",                // [TITLE] followed by newline, then title until newline or bracket
            "\\[TITLE\\]\\s+([^\\[\\n]+)",                   // [TITLE] followed by spaces, then title until newline or bracket  
            "\\[TITLE\\]\\s*([^\\[]+?)(?=\\n\\s*\\[|$)",     // [TITLE] followed by optional spaces, then content until next section
            "\\[TITLE\\]\\s*\\n([\\s\\S]*?)(?=\\n\\s*\\[|$)" // Original pattern as fallback
        ]
        
        for (patternIndex, pattern) in patterns.enumerated() {
            print("🔍 [DynamicParser] Trying pattern \(patternIndex + 1): \(pattern)")
            
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(content.startIndex..., in: content)
            
            if let match = regex?.firstMatch(in: content, options: [], range: range) {
                print("✅ [DynamicParser] Found [TITLE] match with pattern \(patternIndex + 1)!")
                if let swiftRange = Range(match.range(at: 1), in: content) {
                    let title = String(content[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    print("✅ [DynamicParser] Raw extracted title: '\(title)'")
                    print("✅ [DynamicParser] Title length: \(title.count)")
                    print("✅ [DynamicParser] Title is empty: \(title.isEmpty)")
                    if !title.isEmpty && title.count > 3 && title.count < 100 {
                        print("✅ [DynamicParser] Successfully extracted title from [TITLE] section: '\(title)'")
                        return title
                    } else if title.isEmpty {
                        print("⚠️ [DynamicParser] Title extracted but empty after trimming")
                    } else {
                        print("⚠️ [DynamicParser] Title extracted but invalid length: \(title.count)")
                    }
                } else {
                    print("❌ [DynamicParser] Could not convert NSRange to Swift Range")
                }
            }
        }
        
        print("❌ [DynamicParser] No [TITLE] section match found with any pattern")
        
        // Check if [TITLE] exists at all in the content
        if content.contains("[TITLE]") {
            print("🔍 [DynamicParser] [TITLE] found in content but all regex patterns failed")
            if let titleIndex = content.firstIndex(of: "[") {
                let startIndex = max(content.startIndex, content.index(titleIndex, offsetBy: -50))
                let endIndex = min(content.endIndex, content.index(titleIndex, offsetBy: 200))
                let surroundingContext = String(content[startIndex..<endIndex])
                print("🔍 [DynamicParser] Context around [TITLE]: \(surroundingContext)")
            }
        } else {
            print("❌ [DynamicParser] [TITLE] not found anywhere in content")
        }
        
        print("🔄 [DynamicParser] Attempting fallback title extraction...")
        
        // Fallback: look for first meaningful line
        let lines = content.components(separatedBy: .newlines)
        print("🔍 [DynamicParser] Total lines in content: \(lines.count)")
        
        for (index, line) in lines.prefix(10).enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            print("🔍 [DynamicParser] Line \(index): '\(trimmed)' (length: \(trimmed.count), contains bracket: \(trimmed.contains("[")))")
            if !trimmed.isEmpty && !trimmed.contains("[") && trimmed.count > 10 && trimmed.count < 50 {
                print("✅ [DynamicParser] Found fallback title: '\(trimmed)'")
                return trimmed
            }
        }
        
        // NEW: If no [TITLE] section found, try to use the first section name as title
        print("🔄 [DynamicParser] No [TITLE] section found. Trying to extract first section name as title...")
        
        // Pattern to find first bracketed section name
        let firstSectionPattern = "^\\s*\\[([^\\]]+)\\]"
        if let firstSectionRegex = try? NSRegularExpression(pattern: firstSectionPattern, options: []) {
            let range = NSRange(content.startIndex..., in: content)
            if let match = firstSectionRegex.firstMatch(in: content, options: [], range: range) {
                if let titleRange = Range(match.range(at: 1), in: content) {
                    let sectionTitle = String(content[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    print("✅ [DynamicParser] Found first section as title: '\(sectionTitle)'")
                    return sectionTitle
                }
            }
        }
        
        print("❌ [DynamicParser] Could not extract any title, using default fallback")
        return "Parenting Situation"
    }
    
    private func extractAllSections(from content: String, excludingTitle: String? = nil) -> [GuidanceSection] {
        var sections: [GuidanceSection] = []
        var skipFirstSection = false
        
        // Check if we need to skip the first section (if it was used as title)
        if let title = excludingTitle, !content.contains("[TITLE]") {
            // If there's no [TITLE] section and we have a title, it likely came from first section
            skipFirstSection = true
            print("🔍 Dynamic Parser: Will skip first section as it was used for title")
        }
        
        // Find all [SECTION_NAME] patterns
        // Updated to handle sections that may have content on same line or next line
        let sectionPattern = "\\[([^\\]]+)\\]\\s*\\n?([\\s\\S]*?)(?=\\n\\s*\\[|$)"
        guard let regex = try? NSRegularExpression(pattern: sectionPattern, options: []) else {
            print("❌ Dynamic Parser: Failed to create regex")
            return sections
        }
        
        let range = NSRange(content.startIndex..., in: content)
        let matches = regex.matches(in: content, options: [], range: range)
        
        for (index, match) in matches.enumerated() {
            // Extract section title
            guard let titleRange = Range(match.range(at: 1), in: content) else { continue }
            let sectionTitle = String(content[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip TITLE section as it's handled separately
            if sectionTitle.uppercased() == "TITLE" {
                continue
            }
            
            // Skip first section if it was used as the title
            if skipFirstSection && index == 0 {
                print("🔍 Dynamic Parser: Skipping first section '\(sectionTitle)' as it was used for title")
                skipFirstSection = false // Reset flag
                continue
            }
            
            // Extract section content
            guard let contentRange = Range(match.range(at: 2), in: content) else { continue }
            let sectionContent = String(content[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Create section with order based on appearance
            let section = GuidanceSection(
                title: formatSectionTitle(sectionTitle),
                content: sectionContent,
                order: sections.count + 1 // Start from 1, not 0
            )
            
            sections.append(section)
            print("✅ Dynamic Parser: Found section '\(section.title)' with \(sectionContent.count) characters")
        }
        
        return sections
    }
    
    private func formatSectionTitle(_ title: String) -> String {
        // Clean up the section title
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Convert from all caps to title case if needed
        if cleaned == cleaned.uppercased() {
            return cleaned.capitalized
        }
        
        return cleaned
    }
}

// MARK: - Error Handling Extension

extension DynamicGuidanceParser {
    
    func parseWithFallback(_ content: String) -> GuidanceResponseProtocol? {
        print("🔄 Dynamic Parser: Starting comprehensive fallback parsing...")
        
        // Step 1: Try dynamic parsing first
        if let dynamicResponse = parseDynamicGuidanceResponse(content) {
            print("✅ Dynamic Parser: Successfully parsed with dynamic parser")
            return dynamicResponse
        }
        
        print("⚠️ Dynamic Parser: Dynamic parsing failed, trying fixed structure parsing...")
        
        // Step 2: Try fixed parsing logic
        if let fixedResponse = parseWithFixedStructure(content) {
            print("✅ Dynamic Parser: Fixed structure parsing successful")
            return fixedResponse
        }
        
        print("⚠️ Dynamic Parser: Fixed parsing also failed, trying emergency parsing...")
        
        // Step 3: Emergency parsing - try to extract any readable sections
        if let emergencyResponse = parseWithEmergencyFallback(content) {
            print("✅ Dynamic Parser: Emergency parsing successful")
            return emergencyResponse
        }
        
        print("❌ Dynamic Parser: All parsing methods failed")
        return nil
    }
    
    private func parseWithFixedStructure(_ content: String) -> GuidanceResponse? {
        print("🔄 Dynamic Parser: Attempting fixed structure fallback...")
        
        // Extract the fixed 7 sections
        let title = extractFixedSection(from: content, sectionName: "TITLE") ?? "Parenting Situation"
        let situation = extractFixedSection(from: content, sectionName: "SITUATION") ?? "Understanding the Situation"
        let analysis = extractFixedSection(from: content, sectionName: "ANALYSIS") ?? "Analysis of the situation"
        let actionSteps = extractFixedSection(from: content, sectionName: "ACTION STEPS") ?? "Recommended action steps"
        let phrasesToTry = extractFixedSection(from: content, sectionName: "PHRASES TO TRY") ?? "Suggested phrases"
        let quickComebacks = extractFixedSection(from: content, sectionName: "QUICK COMEBACKS") ?? "Quick response ideas"
        let support = extractFixedSection(from: content, sectionName: "SUPPORT") ?? "Additional support information"
        
        return GuidanceResponse(
            title: title,
            situation: situation,
            analysis: analysis,
            actionSteps: actionSteps,
            phrasesToTry: phrasesToTry,
            quickComebacks: quickComebacks,
            support: support,
            overallRecommendation: nil
        )
    }
    
    private func extractFixedSection(from content: String, sectionName: String) -> String? {
        let pattern = "\\[\(NSRegularExpression.escapedPattern(for: sectionName))\\]\\s*\\n([\\s\\S]*?)(?=\\n\\s*\\[|$)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(content.startIndex..., in: content)
        
        if let match = regex?.firstMatch(in: content, options: [], range: range) {
            if let swiftRange = Range(match.range(at: 1), in: content) {
                let extracted = String(content[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                return extracted
            }
        }
        
        return nil
    }
    
    private func parseWithEmergencyFallback(_ content: String) -> DynamicGuidanceResponse? {
        print("🚨 Dynamic Parser: Emergency fallback - attempting to create sections from raw content...")
        
        // Emergency title extraction
        let title = extractTitleEmergency(from: content)
        
        // Try to break content into logical sections by paragraphs
        let sections = createEmergencySections(from: content)
        
        // Only proceed if we have at least 3 sections (minimum requirement)
        guard sections.count >= 3 else {
            print("❌ Emergency Parser: Could not create minimum 3 sections")
            return nil
        }
        
        print("✅ Emergency Parser: Created \(sections.count) emergency sections")
        return DynamicGuidanceResponse(title: title, sections: sections)
    }
    
    private func extractTitleEmergency(from content: String) -> String {
        // Look for any reasonable title in the first few lines
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines.prefix(8) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Look for lines that could be titles
            if !trimmed.isEmpty && 
               trimmed.count > 5 && 
               trimmed.count < 80 &&
               !trimmed.hasPrefix("Content received:") &&
               !trimmed.contains("...") {
                return trimmed
            }
        }
        
        return "Parenting Guidance"
    }
    
    private func createEmergencySections(from content: String) -> [GuidanceSection] {
        var sections: [GuidanceSection] = []
        
        // Split content into paragraphs
        let paragraphs = content.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 20 } // Only substantial paragraphs
        
        // Create sections from the best paragraphs
        let sectionTitles = ["Situation Overview", "Analysis", "Recommendations", "Action Steps", "Support"]
        
        for (index, paragraph) in paragraphs.prefix(5).enumerated() {
            let title = index < sectionTitles.count ? sectionTitles[index] : "Additional Guidance"
            
            sections.append(GuidanceSection(
                title: title,
                content: paragraph,
                order: index + 1
            ))
        }
        
        // Ensure we have at least 3 sections
        while sections.count < 3 {
            let fallbackContent = "Please refer to the complete guidance provided."
            sections.append(GuidanceSection(
                title: "Additional Information",
                content: fallbackContent,
                order: sections.count + 1
            ))
        }
        
        return sections
    }
}