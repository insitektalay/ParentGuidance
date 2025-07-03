import SwiftUI
import Foundation
import Supabase

// OpenAI Service Types
struct GuidanceResponse {
    let title: String
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
    let id: String
    let output: [Output]
    
    struct Output: Codable {
        let content: [Content]
        
        struct Content: Codable {
            let text: String
        }
    }
}

struct NewSituationView: View {
    @State private var isLoading = false
    @State private var guidanceResponse: GuidanceResponse?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            if isLoading {
                print("🔄 Rendering: Loading view")
                return AnyView(SituationOrganizingView())
            } else if let guidance = guidanceResponse {
                print("✅ Rendering: Guidance view with content")
                print("   Situation: \(guidance.situation.prefix(30))...")
                return AnyView(SituationGuidanceViewWithData(guidance: guidance))
            } else {
                print("📝 Rendering: Input view (no guidance yet)")
                return AnyView(SituationInputIdleView(
                    childName: "Alex",
                    onStartRecording: {
                        // handle voice recording
                    },
                    onSendMessage: { inputText in
                        Task {
                            await handleSendMessage(inputText)
                        }
                    }
                ))
            }
        }
        .background(ColorPalette.navy)
    }
    
    private func handleSendMessage(_ inputText: String) async {
        print("🚀 Starting message handling for: \(inputText)")
        isLoading = true
        
        do {
            // Step 1: Get user's family_id first
            print("💾 Step 1: Getting user's family context...")
            let userId = "15359b56-cabf-4b6a-9d2a-a3b11001b8e2"
            let userProfile = try await SimpleOnboardingManager.shared.loadUserProfile(userId: userId)
            print("👥 User family_id: \(userProfile.familyId ?? "nil")")
            
            // If no family_id, create a family for this user
            var familyId = userProfile.familyId
            if familyId == nil {
                print("🏠 No family found, creating family for user...")
                familyId = try await ConversationService.shared.createFamilyForUser(userId: userId)
                print("✅ Created family with ID: \(familyId!)")
            }
            
            // Step 2: Get user's API key
            print("🔑 Step 2: Getting API key for user: \(userId)")
            let apiKey = try await getUserApiKey(userId: userId)
            print("✅ Retrieved API key: \(apiKey.prefix(10))...")
            
            // Step 3: Call OpenAI API to get guidance and title
            print("📡 Step 3: Calling OpenAI API...")
            let guidance = try await generateGuidance(
                situation: inputText,
                familyContext: "none",
                apiKey: apiKey
            )
            print("✅ OpenAI response received successfully")
            print("🏷️ AI-generated title: \(guidance.title)")
            
            // Step 4: Save the situation to database with AI-generated title
            print("💾 Step 4: Saving situation to database with AI title...")
            let situationId = try await ConversationService.shared.saveSituation(
                familyId: familyId,
                childId: nil, // TODO: Get from current child context if needed
                title: guidance.title,
                description: inputText
            )
            print("✅ Situation saved with ID: \(situationId)")
            
            // Step 5: Save the guidance response linked to the situation
            print("💾 Step 5: Saving guidance response to database...")
            let guidanceContent = formatGuidanceForDatabase(guidance)
            let guidanceId = try await ConversationService.shared.saveGuidance(
                situationId: situationId,
                content: guidanceContent,
                category: "parenting_guidance"
            )
            print("✅ Guidance saved with ID: \(guidanceId)")
            print("🔗 Successfully linked situation \(situationId) → guidance \(guidanceId)")
            
            // Step 6: Update UI
            await MainActor.run {
                guidanceResponse = guidance
                isLoading = false
                print("📱 State updated on main thread:")
                print("   isLoading: \(isLoading)")
                print("   guidanceResponse is nil: \(guidanceResponse == nil)")
                if let gr = guidanceResponse {
                    print("   Situation content: \(gr.situation.prefix(30))...")
                }
            }
            print("📱 Guidance response set, UI should update")
            
        } catch {
            print("❌ Error in message handling: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
            }
        }
        
        print("🏁 Message handling completed")
    }
    
    private func formatGuidanceForDatabase(_ guidance: GuidanceResponse) -> String {
        // Convert the structured guidance back to a formatted string for database storage
        return """
        **Title**
        \(guidance.title)
        
        **Situation**
        \(guidance.situation)
        
        **Analysis**
        \(guidance.analysis)
        
        **Action Steps**
        \(guidance.actionSteps)
        
        **Phrases to Try**
        \(guidance.phrasesToTry)
        
        **Quick Comebacks**
        \(guidance.quickComebacks)
        
        **Support**
        \(guidance.support)
        """
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
                "version": "12",
                "variables": [
                    "current_situation": situation,
                    "family_context": familyContext
                ]
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
        
        // Let's see what the actual response looks like
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 Raw response: \(responseString)")
        }
        
        // The prompts API has a different response structure
        let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
        print("✅ JSON decoded successfully")
        print("🔍 Prompt response id: \(promptResponse.id)")
        print("🔍 Output count: \(promptResponse.output.count)")
        
        guard let firstOutput = promptResponse.output.first,
              let firstContent = firstOutput.content.first else {
            print("❌ No content in response")
            throw OpenAIError.noContent
        }
        
        let content = firstContent.text
        
        print("📝 Content received: \(content.prefix(100))...")
        
        // Parse the response into structured guidance
        let guidance = parseGuidanceResponse(content)
        print("✅ Guidance parsed successfully")
        return guidance
    }
    
    private func parseGuidanceResponse(_ content: String) -> GuidanceResponse {
        print("🔍 Parsing content: \(content)")
        
        // Extract each section based on the structured format from the prompt
        let title = extractSection(from: content, title: "Title") ?? "Parenting Situation"
        let situation = extractSection(from: content, title: "Situation") ?? "Understanding the Situation"
        let analysis = extractSection(from: content, title: "Analysis") ?? "Analysis of the situation"
        let actionSteps = extractSection(from: content, title: "Action Steps") ?? "Recommended action steps"
        let phrasesToTry = extractSection(from: content, title: "Phrases to Try") ?? "Suggested phrases"
        let quickComebacks = extractSection(from: content, title: "Quick Comebacks") ?? "Quick response ideas"
        let support = extractSection(from: content, title: "Support") ?? "Additional support information"
        
        print("📝 Parsed sections:")
        print("   Title: \(title)")
        print("   Situation: \(situation.prefix(50))...")
        print("   Analysis: \(analysis.prefix(50))...")
        print("   Action Steps: \(actionSteps.prefix(50))...")
        print("   Phrases to Try: \(phrasesToTry.prefix(50))...")
        print("   Quick Comebacks: \(quickComebacks.prefix(50))...")
        print("   Support: \(support.prefix(50))...")
        
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
    
    private func extractNumberedSteps(from content: String) -> String {
        let lines = content.components(separatedBy: "\n")
        let numberedLines = lines.filter { line in
            line.trimmingCharacters(in: .whitespaces).range(of: "^[0-9]+\\.", options: .regularExpression) != nil
        }
        return numberedLines.joined(separator: "\n\n")
    }
    
    private func extractSection(from content: String, title: String) -> String? {
        // Convert section titles to bracket format
        let bracketTitle: String
        switch title {
        case "Title":
            bracketTitle = "TITLE"
        case "Situation":
            bracketTitle = "SITUATION"
        case "Analysis":
            bracketTitle = "ANALYSIS"
        case "Action Steps":
            bracketTitle = "ACTION STEPS"
        case "Phrases to Try":
            bracketTitle = "PHRASES TO TRY"
        case "Quick Comebacks":
            bracketTitle = "QUICK COMEBACKS"
        case "Support":
            bracketTitle = "SUPPORT"
        default:
            print("❌ Unknown section title: \(title)")
            return nil
        }
        
        // Simple bracket-delimited pattern: [SECTION]\nContent until next [SECTION] or end
        let pattern = "\\[\(NSRegularExpression.escapedPattern(for: bracketTitle))\\]\\s*\\n([\\s\\S]*?)(?=\\n\\s*\\[|$)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(content.startIndex..., in: content)
        
        if let match = regex?.firstMatch(in: content, options: [], range: range) {
            if let swiftRange = Range(match.range(at: 1), in: content) {
                let extracted = String(content[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                print("✅ Extracted \(title): \(extracted.count > 50 ? "\(extracted.prefix(50))..." : extracted)")
                return extracted
            }
        }
        
        print("❌ Failed to extract \(title)")
        print("🔍 Looking for bracket pattern: [\(bracketTitle)]")
        print("🔍 In content: \(content.prefix(200))...")
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
                Text(guidance.title)
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

