import SwiftUI
import Foundation
import Supabase
import Combine

// OpenAI Service Types - using shared types from OpenAIService

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
    @State private var guidanceResponse: GuidanceResponseProtocol?
    @State private var rawGuidanceContent: String? // Store raw OpenAI response
    @State private var userApiKey: String = ""
    @StateObject private var voiceRecorderViewModel = VoiceRecorderViewModel()
    @ObservedObject private var guidanceStructureSettings = GuidanceStructureSettings.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    // Chat mode state
    @State private var chatMessages: [ChatMessage] = []
    @State private var chatIsLoading: Bool = false
    
    // Situation type selection state
    @State private var selectedSituationType: SituationType?
    @State private var showTypePicker = true
    
    var body: some View {
        NavigationStack {
            Group {
                if showTypePicker {
                    // Show situation type picker first
                    SituationTypePickerView(onTypeSelected: { type in
                        selectedSituationType = type
                        showTypePicker = false
                    })
                } else if guidanceStructureSettings.useChatStyleInterface {
                    // Chat-style interface
                    ChatConversationView(
                        messages: $chatMessages,
                        isLoading: $chatIsLoading,
                        childName: "Alex",
                        apiKey: userApiKey,
                        onSendMessage: handleChatMessage
                    )
                } else {
                    // Original card-based interface
                    if isLoading {
                        SituationOrganizingView()
                    } else if let guidance = guidanceResponse {
                        SituationGuidanceViewWithData(guidance: guidance)
                    } else {
                        SituationInputIdleView(
                            voiceRecorderViewModel: voiceRecorderViewModel,
                            childName: "Alex",
                            apiKey: userApiKey,
                            onSendMessage: { inputText in
                                Task {
                                    await handleSendMessage(inputText)
                                }
                            }
                        )
                    }
                }
            }
        }
        .background(ColorPalette.navy)
        .onAppear {
            Task {
                await loadUserApiKey()
            }
        }
    }
    
    private func handleChatMessage(_ inputText: String) async {
        // This is the chat mode handler - it processes the message but updates the chat UI
        
        // Add user message immediately to chat and start loading
        await MainActor.run {
            let userMessage = ChatMessage(text: inputText, sender: .user)
            chatMessages.append(userMessage)
            chatIsLoading = true
        }
        
        do {
            // Step 1: Get user's family_id first
            guard let userId = appCoordinator.currentUserId else {
                print("❌ No current user ID available")
                return
            }
            let userProfile = try await AuthService.shared.loadUserProfile(userId: userId)
            
            // If no family_id, create a family for this user
            var familyId = userProfile.familyId
            if familyId == nil {
                familyId = try await ConversationService.shared.createFamilyForUser(userId: userId)
            }
            
            // Step 2: Get user's API key
            let apiKey = try await getUserApiKey(userId: userId)
            
            // Get selected situation type or default
            let situationType = selectedSituationType ?? .imJustWondering
            
            // Step 2.5: Check for active framework
            let activeFramework = try? await FrameworkStorageService.shared.getActiveFramework(familyId: familyId!)
            
            // Step 2.6: Fetch psychologist notes if toggles are enabled
            let settings = GuidanceStructureSettings.shared
            var childContext: String? = nil
            var keyInsights: String? = nil
            var copingStrategies: String? = nil
            
            if settings.enableChildContext || settings.enableKeyInsights {
                do {
                    let notes = try await PsychologistNoteService.shared.fetchPsychologistNotes(familyId: familyId!)
                    if let latestContextNote = notes.first(where: { $0.noteType == .context }) {
                        if settings.enableChildContext {
                            childContext = latestContextNote.content
                        }
                    }
                    if let latestTraitsNote = notes.first(where: { $0.noteType == .traits }) {
                        if settings.enableKeyInsights {
                            keyInsights = latestTraitsNote.content
                        }
                    }
                } catch {
                    print("⚠️ Failed to fetch psychologist notes: \(error)")
                    // Continue with empty notes - non-blocking
                }
            }
            
            // Step 2.7: Fetch existing coping strategies if toggle is enabled
            if settings.enableCopingStrategies {
                do {
                    let copingInsights = try await ContextualInsightService.shared.fetchCopingStrategies(familyId: familyId!)
                    if !copingInsights.isEmpty {
                        // Convert insights to comma-separated list
                        let strategies = copingInsights.map { $0.content }.joined(separator: ", ")
                        copingStrategies = strategies
                        print("✅ Fetched \(copingInsights.count) coping strategies for guidance")
                    }
                } catch {
                    print("⚠️ Failed to fetch coping strategies: \(error)")
                    // Continue with empty strategies - non-blocking
                }
            }
            
            // Step 3: Generate guidance using GuidanceGenerationService
            let (guidance, rawContent) = try await GuidanceGenerationService.shared.generateGuidance(
                situation: inputText,
                childContext: childContext,
                keyInsights: keyInsights,
                copingStrategies: copingStrategies,
                apiKey: apiKey,
                activeFramework: activeFramework,
                situationType: situationType,
                useStreaming: false // Start with non-streaming for compatibility
            )
            
            // Step 4: Analyze situation for category and incident classification
            let (category, isIncident): (String, Bool)
            if AIProcessingSettings.shared.isSituationAnalysisEnabled() {
                let result = try await ConversationService.shared.analyzeSituation(
                    situationText: inputText,
                    apiKey: apiKey,
                    activeFramework: activeFramework
                )
                category = result.category ?? "general"
                isIncident = result.isIncident
            } else {
                // Use defaults when disabled
                print("⚠️ Situation Analysis disabled - using default values")
                (category, isIncident) = ("general", false)
            }
            
            // Step 5: Save the situation to database with AI-generated title and analysis
            let situationId = try await ConversationService.shared.saveSituation(
                familyId: familyId,
                childId: nil, // TODO: Get from current child context if needed
                title: guidance.title,
                description: inputText,
                situationType: situationType.rawValue,
                category: category,
                isIncident: isIncident
            )
            
            // Step 6: Save the guidance response linked to the situation using raw content
            let guidanceId: String
            do {
                guidanceId = try await ConversationService.shared.saveGuidance(
                    situationId: situationId,
                    content: rawContent, // Use raw bracket-delimited content
                    category: "parenting_guidance",
                    overallRecommendation: guidance.overallRecommendation
                )
                print("✅ Saved guidance with ID: \(guidanceId)")
            } catch {
                print("❌ [CRITICAL] Failed to save guidance in handleChatMessage!")
                print("❌ [CRITICAL] Error: \(error)")
                print("❌ [CRITICAL] Error description: \(error.localizedDescription)")
                // Re-throw to maintain error handling
                throw error
            }
            
            // Step 6.5: Select relevant insights for this guidance (background task)
            Task {
                do {
                    print("🎯 Starting relevant insights selection for guidance: \(guidanceId)")
                    let relevantInsights = try await RelevantInsightsService.shared.selectRelevantInsights(
                        guidanceText: rawContent,
                        situationId: situationId,
                        guidanceId: guidanceId,
                        familyId: familyId!,
                        apiKey: apiKey
                    )
                    print("✅ Successfully selected \(relevantInsights.count) relevant insights")
                    print("🔄 Relevant insights will be visible when you view this guidance again")
                } catch {
                    print("⚠️ Relevant insights selection failed (non-critical): \(error)")
                    print("⚠️ This won't affect the main guidance flow")
                }
            }
            
            // Step 7: Extract contextual insights (background task)
            if AIProcessingSettings.shared.isContextExtractionEnabled() {
                Task {
                    do {
                        let insights = try await ContextualInsightService.shared.extractContextFromSituation(
                            situationText: inputText,
                            apiKey: apiKey,
                            familyId: familyId!,
                            childId: nil, // TODO: Get from current child context if needed
                            situationId: situationId
                        )
                        
                        // Save insights to database
                        try await ContextualInsightService.shared.saveContextInsights(insights)
                    } catch {
                        print("⚠️ Context extraction failed (non-critical): \(error)")
                        print("⚠️ This won't affect the main guidance flow")
                    }
                }
            } else {
                print("⚠️ Context Extraction disabled - skipping 'Your Child's World' insights")
            }
            
            // Step 7.5: Extract child regulation insights (background task)
            if AIProcessingSettings.shared.isRegulationInsightsEnabled() {
                Task {
                    do {
                        let regulationInsights = try await ContextualInsightService.shared.extractChildRegulationInsights(
                            situationText: inputText,
                            apiKey: apiKey,
                            familyId: familyId!,
                            childId: nil, // TODO: Get from current child context if needed
                            situationId: situationId
                        )
                        
                        // Save regulation insights to database
                        try await ContextualInsightService.shared.saveChildRegulationInsights(regulationInsights)
                    } catch {
                        print("⚠️ Child regulation insights extraction failed (non-critical): \(error)")
                        print("⚠️ This won't affect the main guidance flow")
                    }
                }
            } else {
                print("⚠️ Regulation Insights disabled - skipping Core/ADHD/Autism pattern detection")
            }
            
            // Step 7.6: Extract coping strategies (background task)
            if AIProcessingSettings.shared.isCopingStrategiesEnabled() {
                Task {
                    do {
                        let copingStrategies = try await ContextualInsightService.shared.extractCopingStrategies(
                            situationText: inputText,
                            apiKey: apiKey,
                            familyId: familyId!,
                            childId: nil, // TODO: Get from current child context if needed
                            situationId: situationId
                        )
                        
                        // Save coping strategies to database
                        try await ContextualInsightService.shared.saveChildRegulationInsights(copingStrategies)
                    } catch {
                        print("⚠️ Coping strategies extraction failed (non-critical): \(error)")
                        print("⚠️ This won't affect the main guidance flow")
                    }
                }
            } else {
                print("⚠️ Coping Strategies disabled - skipping strategy extraction")
            }
            
            // Step 8: Update chat UI with the full guidance text
            await MainActor.run {
                // Extract all text from the guidance sections for chat display
                let fullGuidanceText = guidance.displaySections
                    .map { "**\($0.title)**\n\n\($0.content)" }
                    .joined(separator: "\n\n")
                
                // Add AI response message to chat and stop loading
                let aiMessage = ChatMessage(text: fullGuidanceText, sender: .ai)
                chatMessages.append(aiMessage)
                chatIsLoading = false
            }
            
        } catch {
            print("❌ Error in chat message handling: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            
            // Update chat with error message
            await MainActor.run {
                let errorMessage = "I encountered an error while processing your request. Please try again."
                let aiMessage = ChatMessage(text: errorMessage, sender: .ai)
                chatMessages.append(aiMessage)
                chatIsLoading = false
            }
        }
    }
    
    private func handleSendMessage(_ inputText: String) async {
        isLoading = true
        
        do {
            // Step 1: Get user's family_id first
            guard let userId = appCoordinator.currentUserId else {
                print("❌ No current user ID available")
                isLoading = false
                return
            }
            let userProfile = try await AuthService.shared.loadUserProfile(userId: userId)
            
            // If no family_id, create a family for this user
            var familyId = userProfile.familyId
            if familyId == nil {
                familyId = try await ConversationService.shared.createFamilyForUser(userId: userId)
            }
            
            // Step 2: Get user's API key
            let apiKey = try await getUserApiKey(userId: userId)
            
            // Get selected situation type or default
            let situationType = selectedSituationType ?? .imJustWondering
            
            // Step 2.5: Check for active framework
            let activeFramework = try? await FrameworkStorageService.shared.getActiveFramework(familyId: familyId!)
            
            // Step 2.6: Fetch psychologist notes if toggles are enabled
            let settings = GuidanceStructureSettings.shared
            var childContext: String? = nil
            var keyInsights: String? = nil
            var copingStrategies: String? = nil
            
            if settings.enableChildContext || settings.enableKeyInsights {
                do {
                    let notes = try await PsychologistNoteService.shared.fetchPsychologistNotes(familyId: familyId!)
                    if let latestContextNote = notes.first(where: { $0.noteType == .context }) {
                        if settings.enableChildContext {
                            childContext = latestContextNote.content
                        }
                    }
                    if let latestTraitsNote = notes.first(where: { $0.noteType == .traits }) {
                        if settings.enableKeyInsights {
                            keyInsights = latestTraitsNote.content
                        }
                    }
                } catch {
                    print("⚠️ Failed to fetch psychologist notes: \(error)")
                    // Continue with empty notes - non-blocking
                }
            }
            
            // Step 2.7: Fetch existing coping strategies if toggle is enabled
            if settings.enableCopingStrategies {
                do {
                    let copingInsights = try await ContextualInsightService.shared.fetchCopingStrategies(familyId: familyId!)
                    if !copingInsights.isEmpty {
                        // Convert insights to comma-separated list
                        let strategies = copingInsights.map { $0.content }.joined(separator: ", ")
                        copingStrategies = strategies
                        print("✅ Fetched \(copingInsights.count) coping strategies for guidance")
                    }
                } catch {
                    print("⚠️ Failed to fetch coping strategies: \(error)")
                    // Continue with empty strategies - non-blocking
                }
            }
            
            // Step 3: Generate guidance using GuidanceGenerationService
            let (guidance, rawContent) = try await GuidanceGenerationService.shared.generateGuidance(
                situation: inputText,
                childContext: childContext,
                keyInsights: keyInsights,
                copingStrategies: copingStrategies,
                apiKey: apiKey,
                activeFramework: activeFramework,
                situationType: situationType,
                useStreaming: false // Start with non-streaming for compatibility
            )
            
            // Step 4: Analyze situation for category and incident classification
            let (category, isIncident): (String, Bool)
            if AIProcessingSettings.shared.isSituationAnalysisEnabled() {
                let result = try await ConversationService.shared.analyzeSituation(
                    situationText: inputText,
                    apiKey: apiKey,
                    activeFramework: activeFramework
                )
                category = result.category ?? "general"
                isIncident = result.isIncident
            } else {
                // Use defaults when disabled
                print("⚠️ Situation Analysis disabled - using default values")
                (category, isIncident) = ("general", false)
            }
            
            // Step 5: Save the situation to database with AI-generated title and analysis
            let situationId = try await ConversationService.shared.saveSituation(
                familyId: familyId,
                childId: nil, // TODO: Get from current child context if needed
                title: guidance.title,
                description: inputText,
                situationType: situationType.rawValue,
                category: category,
                isIncident: isIncident
            )
            
            // Step 6: Save the guidance response linked to the situation using raw content
            let guidanceId: String
            do {
                guidanceId = try await ConversationService.shared.saveGuidance(
                    situationId: situationId,
                    content: rawContent, // Use raw bracket-delimited content
                    category: "parenting_guidance",
                    overallRecommendation: guidance.overallRecommendation
                )
                print("✅ Saved guidance with ID: \(guidanceId)")
            } catch {
                print("❌ [CRITICAL] Failed to save guidance in handleSendMessage!")
                print("❌ [CRITICAL] Error: \(error)")
                print("❌ [CRITICAL] Error description: \(error.localizedDescription)")
                // Re-throw to maintain error handling
                throw error
            }
            
            // Step 6.5: Select relevant insights for this guidance (background task)
            Task {
                do {
                    print("🎯 Starting relevant insights selection for guidance: \(guidanceId)")
                    let relevantInsights = try await RelevantInsightsService.shared.selectRelevantInsights(
                        guidanceText: rawContent,
                        situationId: situationId,
                        guidanceId: guidanceId,
                        familyId: familyId!,
                        apiKey: apiKey
                    )
                    print("✅ Successfully selected \(relevantInsights.count) relevant insights")
                    print("🔄 Relevant insights will be visible when you view this guidance again")
                } catch {
                    print("⚠️ Relevant insights selection failed (non-critical): \(error)")
                    print("⚠️ This won't affect the main guidance flow")
                }
            }
            
            // Step 7: Extract contextual insights (background task)
            if AIProcessingSettings.shared.isContextExtractionEnabled() {
                Task {
                    do {
                        let insights = try await ContextualInsightService.shared.extractContextFromSituation(
                            situationText: inputText,
                            apiKey: apiKey,
                            familyId: familyId!,
                            childId: nil, // TODO: Get from current child context if needed
                            situationId: situationId
                        )
                        
                        // Save insights to database
                        try await ContextualInsightService.shared.saveContextInsights(insights)
                    } catch {
                        print("⚠️ Context extraction failed (non-critical): \(error)")
                        print("⚠️ This won't affect the main guidance flow")
                    }
                }
            } else {
                print("⚠️ Context Extraction disabled - skipping 'Your Child's World' insights")
            }
            
            // Step 7.5: Extract child regulation insights (background task)
            if AIProcessingSettings.shared.isRegulationInsightsEnabled() {
                Task {
                    do {
                        let regulationInsights = try await ContextualInsightService.shared.extractChildRegulationInsights(
                            situationText: inputText,
                            apiKey: apiKey,
                            familyId: familyId!,
                            childId: nil, // TODO: Get from current child context if needed
                            situationId: situationId
                        )
                        
                        // Save regulation insights to database
                        try await ContextualInsightService.shared.saveChildRegulationInsights(regulationInsights)
                    } catch {
                        print("⚠️ Child regulation insights extraction failed (non-critical): \(error)")
                        print("⚠️ This won't affect the main guidance flow")
                    }
                }
            } else {
                print("⚠️ Regulation Insights disabled - skipping Core/ADHD/Autism pattern detection")
            }
            
            // Step 7.6: Extract coping strategies (background task)
            if AIProcessingSettings.shared.isCopingStrategiesEnabled() {
                Task {
                    do {
                        let copingStrategies = try await ContextualInsightService.shared.extractCopingStrategies(
                            situationText: inputText,
                            apiKey: apiKey,
                            familyId: familyId!,
                            childId: nil, // TODO: Get from current child context if needed
                            situationId: situationId
                        )
                        
                        // Save coping strategies to database
                        try await ContextualInsightService.shared.saveChildRegulationInsights(copingStrategies)
                    } catch {
                        print("⚠️ Coping strategies extraction failed (non-critical): \(error)")
                        print("⚠️ This won't affect the main guidance flow")
                    }
                }
            } else {
                print("⚠️ Coping Strategies disabled - skipping strategy extraction")
            }
            
            // Step 8: Update UI
            await MainActor.run {
                guidanceResponse = guidance
                isLoading = false
            }
            
        } catch {
            print("❌ Error in message handling: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    
    private func loadUserApiKey() async {
        guard let userId = appCoordinator.currentUserId else {
            print("❌ No current user ID available for API key loading")
            return
        }
        
        do {
            let apiKey = try await getUserApiKey(userId: userId)
            await MainActor.run {
                userApiKey = apiKey
            }
        } catch {
            print("❌ Failed to load API key: \(error)")
        }
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
        // Use MultiProviderApiKeyService to get the active API key
        guard let apiKey = try await MultiProviderApiKeyService.shared.getLegacyApiKey(for: userId) else {
            throw OpenAIError.apiKeyMissing
        }
        
        return apiKey
    }
    
    private func formatFrameworkForPrompt(_ framework: FrameworkRecommendation) -> String {
        // Validate framework data and provide fallback formatting
        let name = framework.frameworkName.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = framework.notificationText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !name.isEmpty else {
            return "Active Framework: \(description.isEmpty ? "No details available" : description)"
        }
        
        guard !description.isEmpty else {
            return name
        }
        
        return "\(name): \(description)"
    }
    
    /*
    // LEGACY METHOD: Now handled by GuidanceGenerationService
    private func generateGuidance(
        situation: String,
        familyContext: String = "none",
        apiKey: String,
        activeFramework: FrameworkRecommendation? = nil
    ) async throws -> (GuidanceResponseProtocol, String) {
        
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        let (promptId, version, variables): (String, String, [String: Any]) = {
            if let framework = activeFramework {
                // With Framework - Choose version based on style and structure mode
                let version = guidanceStructureSettings.getPromptVersion(hasFramework: true)
                
                // Only include family_context for Fixed Structure mode
                var variables: [String: Any] = [
                    "current_situation": situation,
                    "active_foundation_tools": formatFrameworkForPrompt(framework)
                ]
                if guidanceStructureSettings.currentMode == .fixed {
                    variables["family_context"] = familyContext
                }
                
                return (
                    "pmpt_68516f961dc08190aceb4f591ee010050a454989b0581453",
                    version,
                    variables
                )
            } else {
                // No Framework - Choose version based on style and structure mode
                let version = guidanceStructureSettings.getPromptVersion(hasFramework: false)
                
                // Only include family_context for Fixed Structure mode
                var variables: [String: Any] = ["current_situation": situation]
                if guidanceStructureSettings.currentMode == .fixed {
                    variables["family_context"] = familyContext
                }
                
                return (
                    "pmpt_68515280423c8193aaa00a07235b7cf206c51d869f9526ba",
                    version,
                    variables
                )
            }
        }()
        
        let requestBody: [String: Any] = [
            "prompt": [
                "id": promptId,
                "version": version,
                "variables": variables
            ]
        ]
        
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ HTTP \(httpResponse.statusCode) error: \(responseString)")
            }
            throw OpenAIError.invalidResponse
        }
        
        
        // The prompts API has a different response structure
        let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
        
        guard let firstOutput = promptResponse.output.first,
              let firstContent = firstOutput.content.first else {
            throw OpenAIError.noContent
        }
        
        let content = firstContent.text
        
        // Parse the response into structured guidance based on user preference
        
        let guidance: GuidanceResponseProtocol
        if guidanceStructureSettings.isUsingDynamicStructure {
            // Use dynamic parser for flexible sections with enhanced fallback
            if let dynamicResponse = DynamicGuidanceParser.shared.parseWithFallback(content) {
                guidance = dynamicResponse
            } else {
                // Ultimate fallback: create basic response with error content
                guidance = createFallbackResponse(content: content)
            }
        } else {
            // Use fixed parser for traditional 7-section structure with enhanced validation
            let fixedResponse = parseGuidanceResponse(content)
            if validateGuidanceResponse(fixedResponse) {
                guidance = fixedResponse
            } else {
                guidance = createFallbackResponse(content: content)
            }
        }
        
        return (guidance, content) // Return both parsed guidance and raw content
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
    
    // MARK: - Enhanced Error Handling & Validation
    
    private func validateGuidanceResponse(_ response: GuidanceResponse) -> Bool {
        // Validate that essential sections have meaningful content
        let minContentLength = 10 // Minimum characters for valid content
        
        let validTitle = response.title.count >= 3
        let validSituation = response.situation.count >= minContentLength
        let validAnalysis = response.analysis.count >= minContentLength
        let validActionSteps = response.actionSteps.count >= minContentLength
        
        let isValid = validTitle && validSituation && validAnalysis && validActionSteps
        
        if !isValid {
            print("❌ Validation failed:")
            print("   Title valid: \(validTitle) (length: \(response.title.count))")
            print("   Situation valid: \(validSituation) (length: \(response.situation.count))")
            print("   Analysis valid: \(validAnalysis) (length: \(response.analysis.count))")
            print("   Action Steps valid: \(validActionSteps) (length: \(response.actionSteps.count))")
        }
        
        return isValid
    }
    
    private func createFallbackResponse(content: String) -> GuidanceResponse {
        print("🔧 Creating fallback response from raw content")
        
        // Try to extract at least a title from the content
        let fallbackTitle = extractBasicTitle(from: content) ?? "Parenting Guidance"
        
        // Create a basic structured response with the raw content
        let fallbackContent = """
        We received your situation and our AI provided guidance, but we're having trouble formatting it properly. Here's the complete response:
        
        \(content)
        """
        
        return GuidanceResponse(
            title: fallbackTitle,
            situation: "Your parenting situation has been processed.",
            analysis: fallbackContent.prefix(500).description,
            actionSteps: "Please review the complete guidance above for specific action steps.",
            phrasesToTry: "Please check the complete guidance for suggested phrases.",
            quickComebacks: "Please refer to the complete guidance for response ideas.",
            support: "If you continue to have issues, please try again or contact support."
        )
    }
    
    private func extractBasicTitle(from content: String) -> String? {
        // Simple title extraction as fallback
        let lines = content.components(separatedBy: .newlines)
        
        // Look for the first substantial line that might be a title
        for line in lines.prefix(10) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines, brackets, and very short lines
            if !trimmed.isEmpty && 
               !trimmed.hasPrefix("[") && 
               trimmed.count > 5 && 
               trimmed.count < 100 &&
               !trimmed.contains("Content received:") {
                return trimmed
            }
        }
        
        return nil
    }
    */
}

struct SituationGuidanceViewWithData: View {
    let guidance: GuidanceResponseProtocol
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    private var categories: [GuidanceCategory] {
        guidance.displaySections.map { section in
            GuidanceCategory(title: section.title, content: section.content)
        }
    }
    
    var body: some View {
        ScrollView {
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
                
                // Overall Recommendation Section
                if let recommendation = guidance.overallRecommendation {
                    overallRecommendationView(recommendation: recommendation)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                }
                
                // Guidance cards - maintain natural height
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
                .frame(height: 400) // Set explicit height for cards to prevent compression
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .navigationBarHidden(true)
    }
    
    // MARK: - Overall Recommendation View
    
    @ViewBuilder
    private func overallRecommendationView(recommendation: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ColorPalette.terracotta)
                
                Text("Overall Recommendation")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ColorPalette.white.opacity(0.9))
                
                Spacer()
            }
            
            // Recommendation content
            Text(recommendation)
                .font(.system(size: 16))
                .foregroundColor(ColorPalette.white.opacity(0.8))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ColorPalette.terracotta.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ColorPalette.terracotta.opacity(0.3), lineWidth: 1)
                )
        )
    }
}


