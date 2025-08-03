//
//  SituationDetailView.swift
//  ParentGuidance
//
//  Created by alex kerss on 04/07/2025.
//

import SwiftUI

struct SituationDetailView: View {
    let situation: Situation
    let guidance: [Guidance]
    let isLoadingGuidance: Bool
    let guidanceError: String?
    let onBack: () -> Void
    let onDateUpdated: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showCopyConfirmation = false
    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    @State private var isUpdatingDate = false
    @ObservedObject private var guidanceStructureSettings = GuidanceStructureSettings.shared
    
    // Relevant insights state
    @State private var relevantInsights: [RelevantInsight] = []
    @State private var isLoadingInsights = false
    @State private var isGeneratingInsights = false
    @State private var insightGenerationError: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button and breadcrumb
            VStack(spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(SemanticColors.primaryText)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Breadcrumb
                HStack {
                    Text(String(localized: "tab.library"))
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.tertiaryText)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.tertiaryText)
                    
                    Text(String(localized: "library.situationDetail.title"))
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title with emoji
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: SituationCard.getIconForEmoji(SituationCard.getEmojiForSituation(situation)))
                            .font(.system(size: 24))
                            .foregroundColor(SemanticColors.accent)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(situation.title)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(SemanticColors.primaryText)
                            
                            HStack(spacing: 8) {
                                Text(SituationCard.formatDate(situation.createdAt))
                                    .font(.system(size: 14))
                                    .foregroundColor(SemanticColors.tertiaryText)
                                
                                Button(action: {
                                    // Initialize date picker with current situation date
                                    let formatter = ISO8601DateFormatter()
                                    selectedDate = formatter.date(from: situation.createdAt) ?? Date()
                                    showDatePicker = true
                                }) {
                                    Image(systemName: "pencil.circle")
                                        .font(.system(size: 14))
                                        .foregroundColor(SemanticColors.accent)
                                }
                                .accessibilityLabel(String(localized: "situation.dateEdit.accessibilityLabel"))
                                .accessibilityHint(String(localized: "situation.dateEdit.accessibilityHint"))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    // Guidance Section (moved above situation)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(String(localized: "library.situationDetail.aiGuidance"))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(SemanticColors.primaryText)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        
                        if isLoadingGuidance {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .foregroundColor(SemanticColors.secondaryText)
                                
                                Text(String(localized: "library.situationDetail.loadingGuidance"))
                                    .font(.system(size: 16))
                                    .foregroundColor(SemanticColors.tertiaryText)
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                            
                        } else if let error = guidanceError {
                            VStack(spacing: 16) {
                                Text(String(localized: "library.situationDetail.noGuidance"))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(SemanticColors.primaryText)
                                
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundColor(SemanticColors.tertiaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                            
                        } else if guidance.isEmpty {
                            VStack(spacing: 16) {
                                Text(String(localized: "library.situationDetail.noGuidanceYet"))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(SemanticColors.primaryText)
                                
                                Text(String(localized: "library.situationDetail.notProcessed"))
                                    .font(.system(size: 14))
                                    .foregroundColor(SemanticColors.tertiaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                            
                        } else {
                            // Display guidance content
                            if let firstGuidance = guidance.first {
                                let fullContent = guidance.map { $0.content }.joined(separator: "\n\n")
                                let parsedCategories = parseGuidanceContent(fullContent)
                                
                                if let categories = parsedCategories, !categories.isEmpty {
                                    // Use the same card system as SituationGuidanceView
                                    VStack(spacing: 16) {
                                        // Overall Recommendation Section
                                        if let recommendation = firstGuidance.overallRecommendation {
                                            overallRecommendationView(recommendation: recommendation)
                                                .padding(.bottom, 20)
                                        }
                                        
                                        // Relevant Insights Section
                                        if isLoadingInsights {
                                            RelevantInsightsLoadingView()
                                                .padding(.bottom, 20)
                                        } else if !relevantInsights.isEmpty {
                                            RelevantInsightsSection(insights: relevantInsights)
                                                .padding(.bottom, 20)
                                        } else {
                                            // Generate Insights Button (for missing insights)
                                            generateInsightsButton()
                                                .padding(.bottom, 20)
                                        }
                                        
                                        // Vertical stack of guidance cards
                                        LazyVStack(spacing: 16) {
                                            ForEach(0..<categories.count, id: \.self) { index in
                                                GuidanceCard(
                                                    title: categories[index].title,
                                                    content: categories[index].content,
                                                    isActive: true // All cards are active in vertical layout
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                } else {
                                    // Fallback: show raw guidance content in card format
                                    VStack(spacing: 16) {
                                        GuidanceCard(
                                            title: "Guidance Content",
                                            content: firstGuidance.content,
                                            isActive: true
                                        )
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                    
                    // Original Situation Section (moved below guidance)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(String(localized: "library.situationDetail.originalSituation"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(SemanticColors.secondaryText)
                            
                            Spacer()
                            
                            Button(action: {
                                copyToClipboard(situation.description)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 12))
                                    Text(String(localized: "common.button.copy"))
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(SemanticColors.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(SemanticColors.accent.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                        
                        Text(situation.description)
                            .font(.system(size: 15))
                            .foregroundColor(SemanticColors.primaryText)
                            .lineSpacing(4)
                            .textSelection(.enabled)
                    }
                    .padding(16)
                    .background(SemanticColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(SemanticColors.border, lineWidth: 1)
                    )
                    .if(colorScheme == .light) { view in
                        view.cardShadow()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                }
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SemanticColors.primaryBackground)
        .navigationBarHidden(true)
        .task(id: guidance.first?.id) {
            await loadRelevantInsights()
        }
        .onChange(of: guidance.map(\.id)) { _ in
            Task { await loadRelevantInsights() }
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
        .overlay(
            // Copy confirmation overlay
            VStack {
                if showCopyConfirmation {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                        
                        Text(String(localized: "common.copiedToClipboard"))
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.primaryText)
                    }
                    .padding(16)
                    .background(SemanticColors.primaryBackground.opacity(0.9))
                    .cornerRadius(12)
                    .shadow(radius: 8)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showCopyConfirmation)
        )
    }
    
    // MARK: - Date Picker Sheet
    
    @ViewBuilder
    private var datePickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "situation.dateEdit.description"))
                        .font(.system(size: 16))
                        .foregroundColor(SemanticColors.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 20)
                
                DatePicker(
                    String(localized: "situation.dateEdit.dateLabel"),
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SemanticColors.primaryBackground)
            .navigationTitle(String(localized: "situation.dateEdit.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common.cancel")) {
                        showDatePicker = false
                    }
                    .foregroundColor(SemanticColors.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await updateSituationDate()
                        }
                    }) {
                        if isUpdatingDate {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(SemanticColors.accent)
                        } else {
                            Text(String(localized: "common.save"))
                                .foregroundColor(SemanticColors.accent)
                        }
                    }
                    .disabled(isUpdatingDate)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Date Update Method
    
    private func updateSituationDate() async {
        isUpdatingDate = true
        
        do {
            try await ConversationService.shared.updateSituationDate(
                situationId: situation.id,
                newDate: selectedDate
            )
            
            await MainActor.run {
                showDatePicker = false
                isUpdatingDate = false
                // Notify parent view to refresh
                onDateUpdated?()
            }
            
        } catch {
            await MainActor.run {
                isUpdatingDate = false
                // TODO: Show error alert to user
                print("❌ Failed to update situation date: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helper Methods
    private func parseGuidanceContent(_ content: String) -> [GuidanceCategory]? {
        print("🔍 [DEBUG] SituationDetailView: Parsing guidance content")
        print("   - Settings says use dynamic: \(guidanceStructureSettings.isUsingDynamicStructure)")
        print("   - Content length: \(content.count) characters")
        
        // Parse based on user preference (same logic as SituationGuidanceView)
        if guidanceStructureSettings.isUsingDynamicStructure {
            print("🔄 [DEBUG] SituationDetailView: Using DYNAMIC parsing")
            // Try dynamic parser first
            if let dynamicResponse = DynamicGuidanceParser.shared.parseWithFallback(content) {
                print("✅ [DEBUG] Dynamic parsing SUCCESS - \(dynamicResponse.displaySections.count) sections")
                return dynamicResponse.displaySections.map { section in
                    GuidanceCategory(title: section.title, content: section.content)
                }
            } else {
                print("❌ [DEBUG] Dynamic parsing FAILED, falling back to fixed")
                return parseFixedGuidanceContent(from: content)
            }
        } else {
            print("🔄 [DEBUG] SituationDetailView: Using FIXED parsing")
            return parseFixedGuidanceContent(from: content)
        }
    }
    
    private func parseFixedGuidanceContent(from content: String) -> [GuidanceCategory] {
        // Extract the 6 fixed categories
        return [
            GuidanceCategory(
                title: "Situation",
                content: extractSection(from: content, title: "Situation") ?? "No situation description available."
            ),
            GuidanceCategory(
                title: "Analysis",
                content: extractSection(from: content, title: "Analysis") ?? "No analysis available."
            ),
            GuidanceCategory(
                title: "Action Steps",
                content: extractSection(from: content, title: "Action Steps") ?? "No action steps available."
            ),
            GuidanceCategory(
                title: "Phrases to Try",
                content: extractSection(from: content, title: "Phrases to Try") ?? "No phrases available."
            ),
            GuidanceCategory(
                title: "Quick Comebacks",
                content: extractSection(from: content, title: "Quick Comebacks") ?? "No quick comebacks available."
            ),
            GuidanceCategory(
                title: "Support",
                content: extractSection(from: content, title: "Support") ?? "No support information available."
            )
        ].filter { !$0.content.isEmpty && $0.content != "No \($0.title.lowercased()) available." }
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
            return nil
        }
        
        // Simple bracket-delimited pattern
        let pattern = "\\[\(NSRegularExpression.escapedPattern(for: bracketTitle))\\]\\s*\\n([\\s\\S]*?)(?=\\n\\s*\\[|$)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(content.startIndex..., in: content)
        
        if let match = regex?.firstMatch(in: content, options: [], range: range) {
            if let swiftRange = Range(match.range(at: 1), in: content) {
                return String(content[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return nil
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Show brief confirmation
        showCopyConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopyConfirmation = false
        }
    }
    
    // MARK: - Overall Recommendation View
    
    @ViewBuilder
    private func overallRecommendationView(recommendation: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(SemanticColors.accent)
                
                Text(String(localized: "guidance.overallRecommendation.title"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
            }
            
            // Recommendation content
            Text(recommendation)
                .font(.system(size: 16))
                .foregroundColor(SemanticColors.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SemanticColors.accent.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(SemanticColors.accent.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Relevant Insights Loading
    
    private func loadRelevantInsights() async {
        print("🔔 ENTER loadRelevantInsights() - guidance.count: \(guidance.count)")
        
        // Get the first guidance entry to load insights for
        guard let firstGuidance = guidance.first else {
            print("⛔️ No guidance yet, skipping read - isLoadingGuidance: \(isLoadingGuidance)")
            return
        }
        
        print("➡️ Fetching insights for guidanceId: \(firstGuidance.id)")
        print("📋 [DEBUG] Guidance created at: \(firstGuidance.createdAt)")
        print("📋 [DEBUG] Situation ID: \(situation.id)")
        
        await MainActor.run {
            isLoadingInsights = true
        }
        
        do {
            let insights = try await RelevantInsightsService.shared.getRelevantInsights(guidanceId: firstGuidance.id)
            
            await MainActor.run {
                self.relevantInsights = insights
                self.isLoadingInsights = false
            }
            
            print("✅ [SituationDetailView] Loaded \(insights.count) relevant insights")
            
        } catch {
            print("❌ [SituationDetailView] Failed to load relevant insights: \(error)")
            await MainActor.run {
                self.isLoadingInsights = false
            }
        }
    }
    
    // MARK: - Generate Insights Button
    
    @ViewBuilder
    private func generateInsightsButton() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.2.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(SemanticColors.accent)
                
                Text(String(localized: "insights.relevant.title"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
            }
            
            if isGeneratingInsights {
                // Loading state
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(SemanticColors.accent.opacity(0.7))
                        .scaleEffect(0.8)
                    
                    Text("Generating relevant insights...")
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                }
            } else if let error = insightGenerationError {
                // Error state
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        
                        Text("Failed to generate insights")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SemanticColors.primaryText)
                    }
                    
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.secondaryText)
                        .lineLimit(3)
                    
                    Button("Retry") {
                        Task {
                            await generateRelevantInsights()
                        }
                    }
                    .foregroundColor(SemanticColors.accent)
                    .font(.system(size: 14, weight: .medium))
                }
            } else {
                // Generate button state
                VStack(alignment: .leading, spacing: 12) {
                    Text("No relevant insights found for this guidance. Generate insights by analyzing this guidance against your existing 'Your Child's World' knowledge base.")
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                        .lineSpacing(2)
                    
                    Button(action: {
                        Task {
                            await generateRelevantInsights()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .medium))
                            
                            Text("Generate Relevant Insights")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(SemanticColors.accent)
                        .cornerRadius(8)
                    }
                    .disabled(isGeneratingInsights)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SemanticColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(SemanticColors.accent.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Manual Insights Generation
    
    private func generateRelevantInsights() async {
        guard let firstGuidance = guidance.first else {
            await MainActor.run {
                insightGenerationError = "No guidance found to generate insights for"
            }
            return
        }
        
        await MainActor.run {
            isGeneratingInsights = true
            insightGenerationError = nil
        }
        
        do {
            print("🎯 [SituationDetailView] Manual generation of relevant insights")
            print("🎯 [SituationDetailView] Guidance ID: \(firstGuidance.id)")
            print("🎯 [SituationDetailView] Situation ID: \(situation.id)")
            print("🎯 [SituationDetailView] Family ID: \(situation.familyId ?? "none")")
            
            // Get user's API key
            guard let userId = SupabaseManager.shared.client.auth.currentUser?.id.uuidString else {
                throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            let apiKey = try await getUserApiKey(userId: userId)
            
            // Generate insights using historical context (filter by situation date)
            let insights = try await RelevantInsightsService.shared.selectRelevantInsightsForHistoricalSituation(
                guidanceText: firstGuidance.content,
                situationId: situation.id,
                guidanceId: firstGuidance.id,
                familyId: situation.familyId ?? "",
                situationDate: situation.createdAt,
                apiKey: apiKey
            )
            
            await MainActor.run {
                self.relevantInsights = insights
                self.isGeneratingInsights = false
                
                if insights.isEmpty {
                    self.insightGenerationError = "No relevant insights found. This could mean you don't have enough insights in your 'Your Child's World' knowledge base yet, or none match this guidance."
                }
            }
            
            print("✅ [SituationDetailView] Generated \(insights.count) relevant insights")
            
        } catch {
            print("❌ [SituationDetailView] Manual insight generation failed: \(error)")
            await MainActor.run {
                self.isGeneratingInsights = false
                self.insightGenerationError = "Failed to generate insights: \(error.localizedDescription)"
            }
        }
    }
    
    private func getUserApiKey(userId: String) async throws -> String {
        guard let apiKey = try await MultiProviderApiKeyService.shared.getLegacyApiKey(for: userId) else {
            throw NSError(domain: "ApiKey", code: 404, userInfo: [NSLocalizedDescriptionKey: "No API key found"])
        }
        return apiKey
    }
}


#Preview {
    SituationDetailView(
        situation: Situation(
            familyId: "test",
            childId: nil,
            title: "Morning teeth brushing routine",
            description: "My 5-year-old refuses to brush their teeth every morning. It's becoming a daily battle and we're often late for school because of it.",
            category: "Routine-Building",
            isIncident: true
        ),
        guidance: [],
        isLoadingGuidance: false,
        guidanceError: nil,
        onBack: {},
        onDateUpdated: nil
    )
}