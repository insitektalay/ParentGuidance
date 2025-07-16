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
        print("📄 Content preview: \(String(content.prefix(200)))...")
        
        // Extract title first
        guard let title = extractTitle(from: content) else {
            print("❌ Dynamic Parser: Failed to extract title")
            return nil
        }
        
        // Extract all dynamic sections
        let sections = extractAllSections(from: content)
        
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
        // Look for [TITLE] section
        let pattern = "\\[TITLE\\]\\s*\\n([\\s\\S]*?)(?=\\n\\s*\\[|$)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(content.startIndex..., in: content)
        
        if let match = regex?.firstMatch(in: content, options: [], range: range) {
            if let swiftRange = Range(match.range(at: 1), in: content) {
                let title = String(content[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                print("✅ Dynamic Parser: Extracted title: '\(title)'")
                return title
            }
        }
        
        // Fallback: try to find first line that looks like a title
        let lines = content.components(separatedBy: .newlines)
        for line in lines.prefix(5) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.contains("[") && trimmed.count > 10 && trimmed.count < 50 {
                print("✅ Dynamic Parser: Fallback title: '\(trimmed)'")
                return trimmed
            }
        }
        
        print("❌ Dynamic Parser: Could not extract title")
        return "Parenting Situation"
    }
    
    private func extractAllSections(from content: String) -> [GuidanceSection] {
        var sections: [GuidanceSection] = []
        
        // Find all [SECTION_NAME] patterns
        let sectionPattern = "\\[([^\\]]+)\\]\\s*\\n([\\s\\S]*?)(?=\\n\\s*\\[|$)"
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
            support: support
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