import SwiftUI
import Foundation

// OpenAI Service Types
struct GuidanceResponse {
    let situation: String
    let analysis: String
    let actionSteps: String
    let phrasesToTry: String
    let quickComebacks: String
    let support: String
}

enum OpenAIError: Error {
    case invalidResponse
    case noContent
    case apiKeyMissing
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

struct PromptResponse: Codable {
    let content: String?
    let id: String?
    let created: Int?
}

struct NewSituationView: View {
    @State private var isLoading = false
    @State private var guidanceResponse: GuidanceResponse?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            if isLoading {
                SituationOrganizingView()
            } else if let guidance = guidanceResponse {
                SituationGuidanceViewWithData(guidance: guidance)
            } else {
                SituationInputIdleView(
                    childName: "Alex",
                    onStartRecording: {
                        // handle voice recording
                    },
                    onSendMessage: { inputText in
                        Task {
                            await handleSendMessage(inputText)
                        }
                    }
                )
            }
        }
        .background(ColorPalette.navy)
    }
    
    private func handleSendMessage(_ inputText: String) async {
        print("🚀 Starting message handling for: \(inputText)")
        isLoading = true
        
        do {
            // Get user's API key from database
            let userId = "15359b56-cabf-4b6a-9d2a-a3b11001b8e2" // Current test user
            print("🔑 Getting API key for user: \(userId)")
            let apiKey = try await getUserApiKey(userId: userId)
            print("✅ Retrieved API key: \(apiKey.prefix(10))...")
            
            // Call OpenAI API
            print("📡 Calling OpenAI API...")
            let guidance = try await generateGuidance(
                situation: inputText,
                familyContext: "none",
                apiKey: apiKey
            )
            print("✅ OpenAI response received successfully")
            
            await MainActor.run {
                guidanceResponse = guidance
                isLoading = false
            }
            print("📱 Guidance response set, UI should update")
            
        } catch {
            print("❌ Error generating guidance: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
            }
        }
        
        print("🏁 Message handling completed")
    }
    
    private func getUserApiKey(userId: String) async throws -> String {
        let supabase = SupabaseManager.shared.client
        
        // Query just the API key field and decode as a dictionary
        let response: [[String: String?]] = try await supabase
            .from("profiles")
            .select("user_api_key")
            .eq("id", value: userId)
            .execute()
            .value
        
        guard let row = response.first,
              let apiKey = row["user_api_key"] as? String,
              !apiKey.isEmpty else {
            throw OpenAIError.apiKeyMissing
        }
        
        return apiKey
    }
    
    private func generateGuidance(
        situation: String,
        familyContext: String = "none",
        apiKey: String,
        promptId: String = "pmpt_68515280423c8193aaa00a07235b7cf206c51d869f9526ba"
    ) async throws -> GuidanceResponse {
        
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "prompt": [
                "id": promptId,
                "version": "6"
            ],
            "variables": [
                "current_situation": situation,
                "family_context": familyContext
            ]
        ]
        
        print("🔗 API URL: \(url)")
        print("📦 Request body: \(requestBody)")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("📡 Making API request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("📊 Response received. Status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw OpenAIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ HTTP error: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(responseString)")
            }
            throw OpenAIError.invalidResponse
        }
        
        print("✅ HTTP 200 response received")
        
        // The prompts API has a different response structure
        let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
        print("✅ JSON decoded successfully")
        
        guard let content = promptResponse.content else {
            print("❌ No content in response")
            throw OpenAIError.noContent
        }
        
        print("📝 Content received: \(content.prefix(100))...")
        
        // Parse the response into structured guidance
        let guidance = parseGuidanceResponse(content)
        print("✅ Guidance parsed successfully")
        return guidance
    }
    
    private func parseGuidanceResponse(_ content: String) -> GuidanceResponse {
        print("🔍 Parsing content: \(content)")
        
        // For now, let's use the full content and break it into logical sections
        // Later we can improve this to parse structured responses
        
        let sections = content.components(separatedBy: "\n\n")
        
        let situation = "Understanding the Situation"
        let analysis = sections.first ?? "Analysis of the situation"
        let actionSteps = extractNumberedSteps(from: content)
        let phrasesToTry = "Try saying: 'Let's make tooth brushing fun together!'"
        let quickComebacks = "Remember: Stay patient and positive"
        let support = sections.last ?? "Additional support information"
        
        print("📝 Parsed sections:")
        print("   Situation: \(situation)")
        print("   Analysis: \(analysis)")
        print("   Action Steps: \(actionSteps)")
        print("   Phrases to Try: \(phrasesToTry)")
        print("   Quick Comebacks: \(quickComebacks)")
        print("   Support: \(support)")
        
        return GuidanceResponse(
            situation: situation,
            analysis: analysis,
            actionSteps: actionSteps,
            phrasesToTry: phrasesToTry,
            quickComebacks: quickComebacks,
            support: support
        )
    }
    
    private func extractNumberedSteps(from content: String) -> String {
        let lines = content.components(separatedBy: "\n")
        let numberedLines = lines.filter { line in
            line.trimmingCharacters(in: .whitespaces).range(of: "^[0-9]+\\.", options: .regularExpression) != nil
        }
        return numberedLines.joined(separator: "\n\n")
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

struct SituationGuidanceViewWithData: View {
    let guidance: GuidanceResponse
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    private var categories: [GuidanceCategory] {
        [
            GuidanceCategory(title: "Situation", content: guidance.situation),
            GuidanceCategory(title: "Analysis", content: guidance.analysis),
            GuidanceCategory(title: "Action Steps", content: guidance.actionSteps),
            GuidanceCategory(title: "Phrases to Try", content: guidance.phrasesToTry),
            GuidanceCategory(title: "Quick Comebacks", content: guidance.quickComebacks),
            GuidanceCategory(title: "Support", content: guidance.support)
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack(alignment: .center, spacing: 12) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)
            
            // Title
            HStack {
                Text("Parenting Guidance")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(ColorPalette.white.opacity(0.9))
                    .padding(.horizontal, 16)
                
                Spacer()
            }
            .padding(.bottom, 16)
            
            // Guidance cards
            TabView(selection: $currentPage) {
                ForEach(0..<categories.count, id: \.self) { index in
                    GuidanceCard(
                        title: categories[index].title,
                        content: categories[index].content,
                        isActive: index == currentPage
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .padding(.horizontal, 16)
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<categories.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? ColorPalette.terracotta : ColorPalette.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .navigationBarHidden(true)
    }
}

