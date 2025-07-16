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
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    let _ = print("🔄 Rendering: Loading view")
                    SituationOrganizingView()
                } else if let guidance = guidanceResponse {
                    let _ = print("✅ Rendering: Guidance view with content")
                    let _ = print("   Title: \(guidance.title)")
                    let _ = print("   Sections: \(guidance.sectionCount)")
                    SituationGuidanceViewWithData(guidance: guidance)
                } else {
                    let _ = print("📝 Rendering: Input view (no guidance yet)")
                    SituationInputIdleView(
                        childName: "Alex",
                        apiKey: userApiKey,
                        onStartRecording: {
                            // Recording is now handled internally by SituationInputIdleView
                        },
                        onSendMessage: { inputText in
                            Task {
                                await handleSendMessage(inputText)
                            }
                        }
                    )
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
    
    private func handleSendMessage(_ inputText: String) async {
        print("🚀 Starting message handling for: \(inputText)")
        isLoading = true
        
        do {
            // Step 1: Get user's family_id first
            print("💾 Step 1: Getting user's family context...")
            guard let userId = appCoordinator.currentUserId else {
                print("❌ No current user ID available")
                isLoading = false
                return
            }
            let userProfile = try await AuthService.shared.loadUserProfile(userId: userId)
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
            
            // Step 2.5: Check for active framework
            print("🔍 Step 2.5: Checking for active framework...")
            let activeFramework = try? await FrameworkStorageService.shared.getActiveFramework(familyId: familyId!)
            if let framework = activeFramework {
                print("✅ Found active framework: \(framework.frameworkName)")
            } else {
                print("📭 No active framework found")
            }
            
            // Step 3: Call OpenAI API to get guidance and title
            print("📡 Step 3: Calling OpenAI API...")
            let (guidance, rawContent) = try await generateGuidance(
                situation: inputText,
                familyContext: "none",
                apiKey: apiKey,
                activeFramework: activeFramework
            )
            print("✅ OpenAI response received successfully")
            print("🏷️ AI-generated title: \(guidance.title)")
            
            // Step 4: Analyze situation for category and incident classification
            print("🔍 Step 4: Analyzing situation...")
            let (category, isIncident) = try await ConversationService.shared.analyzeSituation(
                situationText: inputText,
                apiKey: apiKey,
                activeFramework: activeFramework
            )
            print("✅ Analysis completed - Category: \(category ?? "nil"), Incident: \(isIncident)")
            
            // Step 5: Save the situation to database with AI-generated title and analysis
            print("💾 Step 5: Saving situation to database with AI title and analysis...")
            let situationId = try await ConversationService.shared.saveSituation(
                familyId: familyId,
                childId: nil, // TODO: Get from current child context if needed
                title: guidance.title,
                description: inputText,
                category: category,
                isIncident: isIncident
            )
            print("✅ Situation saved with ID: \(situationId)")
            
            // Step 6: Save the guidance response linked to the situation using raw content
            print("💾 Step 6: Saving guidance response to database...")
            print("🔍 [DEBUG] About to call saveGuidance with:")
            print("   - situationId: \(situationId)")
            print("   - rawContent length: \(rawContent.count)")
            print("   - rawContent sample: \(rawContent.prefix(200))...")
            
            do {
                let guidanceId = try await ConversationService.shared.saveGuidance(
                    situationId: situationId,
                    content: rawContent, // Use raw bracket-delimited content
                    category: "parenting_guidance"
                )
                print("✅ Guidance saved with ID: \(guidanceId)")
                print("🔗 Successfully linked situation \(situationId) → guidance \(guidanceId)")
            } catch {
                print("❌ [CRITICAL] Failed to save guidance in handleSendMessage!")
                print("❌ [CRITICAL] Error: \(error)")
                print("❌ [CRITICAL] Error description: \(error.localizedDescription)")
                // Re-throw to maintain error handling
                throw error
            }
            
            // Step 7: Update UI
            await MainActor.run {
                guidanceResponse = guidance
                isLoading = false
                print("📱 State updated on main thread:")
                print("   isLoading: \(isLoading)")
                print("   guidanceResponse is nil: \(guidanceResponse == nil)")
                if let gr = guidanceResponse {
                    print("   Guidance title: \(gr.title)")
                    print("   Section count: \(gr.sectionCount)")
                    print("   Sections: \(gr.displaySections.map { $0.title }.joined(separator: ", "))")
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
    
    
    private func loadUserApiKey() async {
        guard let userId = appCoordinator.currentUserId else {
            print("❌ No current user ID available for API key loading")
            return
        }
        
        do {
            let apiKey = try await getUserApiKey(userId: userId)
            await MainActor.run {
                userApiKey = apiKey
                print("✅ API key loaded successfully")
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
        
        // Debug: Log current settings state
        print("🔍 [DEBUG] Current guidance structure settings:")
        print("   - Current mode: \(guidanceStructureSettings.currentMode.displayName)")
        print("   - Is using dynamic: \(guidanceStructureSettings.isUsingDynamicStructure)")
        print("   - Has active framework: \(activeFramework != nil)")
        
        let (promptId, version, variables): (String, String, [String: Any]) = {
            if let framework = activeFramework {
                // With Framework - Choose version based on mode
                let version = guidanceStructureSettings.isUsingDynamicStructure ? "5" : "3"
                print("🔍 [DEBUG] Framework path - Selected version: \(version) (dynamic: \(guidanceStructureSettings.isUsingDynamicStructure))")
                return (
                    "pmpt_68516f961dc08190aceb4f591ee010050a454989b0581453",
                    version,
                    [
                        "current_situation": situation,
                        "active_foundation_tools": formatFrameworkForPrompt(framework)
                    ]
                )
            } else {
                // No Framework - Choose version based on mode
                let version = guidanceStructureSettings.isUsingDynamicStructure ? "16" : "12"
                print("🔍 [DEBUG] No framework path - Selected version: \(version) (dynamic: \(guidanceStructureSettings.isUsingDynamicStructure))")
                return (
                    "pmpt_68515280423c8193aaa00a07235b7cf206c51d869f9526ba",
                    version,
                    [
                        "current_situation": situation,
                        "family_context": familyContext
                    ]
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
        
        print("🔗 API URL: \(url)")
        print("📦 [DEBUG] Full request body:")
        print("   - Prompt ID: \(promptId)")
        print("   - Version: \(version)")
        print("   - Variables: \(variables)")
        print("📦 Complete request: \(requestBody)")
        
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
        
        print("📝 [DEBUG] Raw OpenAI response content:")
        print("   - Length: \(content.count) characters")
        print("   - First 200 chars: \(content.prefix(200))...")
        print("   - Contains brackets: \(content.contains("[") && content.contains("]"))")
        
        // Parse the response into structured guidance based on user preference
        print("🔍 [DEBUG] Parsing decision:")
        print("   - Settings says use dynamic: \(guidanceStructureSettings.isUsingDynamicStructure)")
        print("   - About to enter \(guidanceStructureSettings.isUsingDynamicStructure ? "DYNAMIC" : "FIXED") parsing path")
        
        let guidance: GuidanceResponseProtocol
        if guidanceStructureSettings.isUsingDynamicStructure {
            print("🔄 [DEBUG] ENTERING DYNAMIC PARSING PATH")
            // Use dynamic parser for flexible sections with enhanced fallback
            if let dynamicResponse = DynamicGuidanceParser.shared.parseWithFallback(content) {
                guidance = dynamicResponse
                print("✅ [DEBUG] Dynamic parsing SUCCESS - \(dynamicResponse.displaySections.count) sections")
                print("   - Section titles: \(dynamicResponse.displaySections.map { $0.title }.joined(separator: ", "))")
            } else {
                // Ultimate fallback: create basic response with error content
                print("❌ [DEBUG] All dynamic parsing methods FAILED, creating fallback response")
                guidance = createFallbackResponse(content: content)
            }
        } else {
            print("🔄 [DEBUG] ENTERING FIXED PARSING PATH")
            // Use fixed parser for traditional 7-section structure with enhanced validation
            let fixedResponse = parseGuidanceResponse(content)
            if validateGuidanceResponse(fixedResponse) {
                guidance = fixedResponse
                print("✅ [DEBUG] Fixed parsing SUCCESS with validation")
            } else {
                print("⚠️ [DEBUG] Fixed parsing validation FAILED, creating enhanced fallback")
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

// MARK: - VoiceRecorderViewModel

@MainActor
class VoiceRecorderViewModel: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var transcriptionText: String = ""
    @Published var isTranscribing: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false
    
    private let voiceRecorder = VoiceRecorderService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        voiceRecorder.delegate = self
    }
    
    private func setupBindings() {
        // Bind to voice recorder's published properties
        voiceRecorder.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)
        
        voiceRecorder.$recordingDuration
            .receive(on: DispatchQueue.main)
            .assign(to: \.recordingDuration, on: self)
            .store(in: &cancellables)
    }
    
    func startRecording() async {
        print("🎙️ ViewModel: Starting recording...")
        clearError()
        
        do {
            let _ = try await voiceRecorder.startRecording()
            print("✅ ViewModel: Recording started successfully")
        } catch {
            print("❌ ViewModel: Recording failed - \(error)")
            await handleError(error)
        }
    }
    
    func stopRecordingAndTranscribe(apiKey: String) async throws -> (recordingURL: URL, transcription: String) {
        print("🛑 ViewModel: Stopping recording and transcribing...")
        
        do {
            // Set transcribing state first to avoid timing gap
            isTranscribing = true
            
            let result = try await voiceRecorder.stopRecordingAndTranscribe(apiKey: apiKey)
            transcriptionText = result.transcription
            
            // Only reset transcribing state after everything is complete
            isTranscribing = false
            print("✅ ViewModel: Transcription completed: \(result.transcription)")
            return result
        } catch {
            print("❌ ViewModel: Stop and transcribe failed - \(error)")
            isTranscribing = false
            await handleError(error)
            throw error
        }
    }
    
    func cancelRecording() async {
        print("❌ ViewModel: Canceling recording...")
        await voiceRecorder.cancelRecording()
        clearError()
    }
    
    func clearTranscription() {
        transcriptionText = ""
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    private func handleError(_ error: Error) async {
        let voiceError = error as? VoiceRecorderError ?? VoiceRecorderError.unknown(error)
        errorMessage = voiceError.userFriendlyMessage
        showError = true
        print("❌ ViewModel: Error set - \(errorMessage ?? "nil")")
    }
    
    // MARK: - Formatted Duration
    
    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - UI State Helpers
    
    var canStartRecording: Bool {
        !isRecording && !isTranscribing
    }
    
    var canStopRecording: Bool {
        isRecording && !isTranscribing
    }
    
    var isProcessing: Bool {
        isTranscribing
    }
}

// MARK: - VoiceRecorderDelegate

extension VoiceRecorderViewModel: VoiceRecorderDelegate {
    nonisolated func voiceRecorderWillStartRecording(_ recorder: VoiceRecorderService) {
        print("🎙️ ViewModel Delegate: Will start recording")
    }
    
    nonisolated func voiceRecorderDidStartRecording(_ recorder: VoiceRecorderService, fileURL: URL) {
        print("🎙️ ViewModel Delegate: Did start recording at \(fileURL.lastPathComponent)")
    }
    
    nonisolated func voiceRecorderDidStopRecording(_ recorder: VoiceRecorderService, fileURL: URL, duration: TimeInterval) {
        print("🛑 ViewModel Delegate: Did stop recording - duration: \(duration)s")
    }
    
    nonisolated func voiceRecorderDidCancelRecording(_ recorder: VoiceRecorderService) {
        print("❌ ViewModel Delegate: Did cancel recording")
    }
    
    nonisolated func voiceRecorderWillStartTranscription(_ recorder: VoiceRecorderService, fileURL: URL) {
        print("🎤 ViewModel Delegate: Will start transcription")
    }
    
    nonisolated func voiceRecorderDidCompleteTranscription(_ recorder: VoiceRecorderService, transcription: String, fileURL: URL) {
        print("✅ ViewModel Delegate: Transcription completed")
    }
    
    nonisolated func voiceRecorderDidCompleteRecordingAndTranscription(_ recorder: VoiceRecorderService, transcription: String, fileURL: URL, duration: TimeInterval) {
        print("✅ ViewModel Delegate: Complete flow finished - transcription: \(transcription.prefix(50))...")
    }
    
    nonisolated func voiceRecorderDidEncounterError(_ recorder: VoiceRecorderService, error: VoiceRecorderError) {
        print("❌ ViewModel Delegate: Error encountered - \(error)")
        Task { @MainActor in
            await handleError(error)
        }
    }
    
    nonisolated func voiceRecorderDidUpdateRecordingDuration(_ recorder: VoiceRecorderService, duration: TimeInterval) {
        // This is handled automatically by the @Published binding
    }
}

