import Foundation

class OpenAIService {
    static let shared = OpenAIService()
    
    private init() {}
    
    func generateGuidance(
        situation: String,
        familyContext: String = "none",
        apiKey: String,
        promptId: String = "pmpt_68515280423c8193aaa00a07235b7cf206c51d869f9526ba"
    ) async throws -> GuidanceResponse {
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                [
                    "role": "user",
                    "content": "Current situation: \(situation)\nFamily context: \(familyContext)\n\nPlease provide guidance using prompt ID: \(promptId)"
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response type")
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP error: \(httpResponse.statusCode)")
            if let errorBody = String(data: data, encoding: .utf8) {
                print("📄 Error response: \(errorBody)")
            }
            throw OpenAIError.invalidResponse
        }
        
        print("✅ Received successful HTTP response")
        
        do {
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            
            guard let content = openAIResponse.choices.first?.message.content else {
                print("❌ No content in OpenAI response")
                throw OpenAIError.noContent
            }
            
            print("✅ Successfully extracted content from OpenAI response")
            
            // Parse the response into structured guidance
            return parseGuidanceResponse(content)
        } catch {
            print("❌ Failed to decode OpenAI response: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(jsonString.prefix(500))...")
            }
            throw OpenAIError.invalidResponse
        }
    }
    
    private func parseGuidanceResponse(_ content: String) -> GuidanceResponse {
        print("🔍 Parsing guidance response with improved logic...")
        print("📄 Content preview: \(String(content.prefix(200)))...")
        
        let extractedSections = extractAllSections(from: content)
        
        let result = GuidanceResponse(
            title: extractedSections.title ?? createFallbackTitle(from: content),
            situation: extractedSections.situation ?? createFallbackSituation(from: content),
            analysis: extractedSections.analysis ?? "Analysis of the situation",
            actionSteps: extractedSections.actionSteps ?? "Recommended action steps",
            phrasesToTry: extractedSections.phrasesToTry ?? "Suggested phrases",
            quickComebacks: extractedSections.quickComebacks ?? "Quick response ideas",
            support: extractedSections.support ?? "Additional support information"
        )
        
        print("✅ Parsing completed. Title: '\(result.title)'")
        return result
    }
    
    private func extractAllSections(from content: String) -> (
        title: String?,
        situation: String?,
        analysis: String?,
        actionSteps: String?,
        phrasesToTry: String?,
        quickComebacks: String?,
        support: String?
    ) {
        return (
            title: extractTitle(from: content),
            situation: extractSection(from: content, sectionName: "Situation"),
            analysis: extractSection(from: content, sectionName: "Analysis"),
            actionSteps: extractSection(from: content, sectionName: "Action Steps"),
            phrasesToTry: extractSection(from: content, sectionName: "Phrases to Try"),
            quickComebacks: extractSection(from: content, sectionName: "Quick Comebacks"),
            support: extractSection(from: content, sectionName: "Support")
        )
    }
    
    private func createFallbackTitle(from content: String) -> String {
        // Try to extract first meaningful sentence as title
        let lines = content.components(separatedBy: .newlines)
        for line in lines.prefix(5) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.contains(":") && trimmed.count > 10 && trimmed.count < 50 {
                return trimmed
            }
        }
        return "Parenting Situation"
    }
    
    private func createFallbackSituation(from content: String) -> String {
        // Try to extract first paragraph as situation summary
        let paragraphs = content.components(separatedBy: "\n\n")
        for paragraph in paragraphs.prefix(3) {
            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 50 && !trimmed.contains("Title:") {
                return String(trimmed.prefix(200)) + (trimmed.count > 200 ? "..." : "")
            }
        }
        return "Situation analysis"
    }
    
    private func extractTitle(from content: String) -> String? {
        // Title format: "Title: Managing After-School Overwhelm"
        let pattern = "Title:\\s*(.+?)(?=\\n|$)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(content.startIndex..., in: content)
        
        if let match = regex?.firstMatch(in: content, options: [], range: range) {
            if let swiftRange = Range(match.range(at: 1), in: content) {
                let title = String(content[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                print("✅ Extracted title: '\(title)'")
                return title
            }
        }
        
        print("❌ Failed to extract title")
        return nil
    }
    
    private func extractSection(from content: String, sectionName: String) -> String? {
        // Section format: "Situation  \nContent here...\n\nNext Section"
        // Pattern matches section name followed by whitespace, then captures content until next section or end
        let pattern = "\(NSRegularExpression.escapedPattern(for: sectionName))\\s*\\n([\\s\\S]*?)(?=\\n\\s*(?:Situation|Analysis|Action Steps|Phrases to Try|Quick Comebacks|Support)\\s*\\n|$)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(content.startIndex..., in: content)
        
        if let match = regex?.firstMatch(in: content, options: [], range: range) {
            if let swiftRange = Range(match.range(at: 1), in: content) {
                let section = String(content[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                print("✅ Extracted \(sectionName): '\(String(section.prefix(50)))...'")
                return section
            }
        }
        
        print("❌ Failed to extract \(sectionName)")
        return nil
    }
}

struct GuidanceResponse {
    let title: String
    let situation: String
    let analysis: String
    let actionSteps: String
    let phrasesToTry: String
    let quickComebacks: String
    let support: String
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}

enum OpenAIError: Error {
    case invalidResponse
    case noContent
    case apiKeyMissing
}