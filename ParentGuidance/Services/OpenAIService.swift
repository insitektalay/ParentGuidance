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
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenAIError.invalidResponse
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw OpenAIError.noContent
        }
        
        // Parse the response into structured guidance
        return parseGuidanceResponse(content)
    }
    
    private func parseGuidanceResponse(_ content: String) -> GuidanceResponse {
        // For now, create a basic structure - this can be enhanced later
        return GuidanceResponse(
            situation: extractSection(from: content, title: "Situation") ?? "Situation analysis",
            analysis: extractSection(from: content, title: "Analysis") ?? "Analysis of the situation",
            actionSteps: extractSection(from: content, title: "Action Steps") ?? "Recommended action steps",
            phrasesToTry: extractSection(from: content, title: "Phrases to Try") ?? "Suggested phrases",
            quickComebacks: extractSection(from: content, title: "Quick Comebacks") ?? "Quick response ideas",
            support: extractSection(from: content, title: "Support") ?? "Additional support information"
        )
    }
    
    private func extractSection(from content: String, title: String) -> String? {
        let pattern = "\(title):\\s*([\\s\\S]*?)(?=\\n\\n[A-Z]|$)"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(content.startIndex..., in: content)
        
        if let match = regex?.firstMatch(in: content, options: [], range: range) {
            if let swiftRange = Range(match.range(at: 1), in: content) {
                return String(content[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return nil
    }
}

struct GuidanceResponse {
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