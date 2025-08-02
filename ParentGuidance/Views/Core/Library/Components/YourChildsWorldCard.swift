//
//  YourChildsWorldCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 17/07/2025.
//

import SwiftUI

struct YourChildsWorldCard: View {
    let familyId: String?
    let onViewInsights: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var insightCounts: [ContextCategory: Int] = [:]
    @State private var isLoading: Bool = false
    @State private var hasError: Bool = false
    @State private var isRegenerating: Bool = false
    @State private var showingRegenerateConfirmation: Bool = false
    @State private var showingRegenerateSuccess: Bool = false
    @State private var showingRegenerateError: Bool = false
    @State private var regenerateErrorMessage: String = ""
    @State private var regenerateResultCounts: [ContextCategory: Int] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(SemanticColors.accentBlue)
                
                Text(String(localized: "library.childsWorld.title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
            }
            
            // Description and insight count
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "library.childsWorld.subtitle"))
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.secondaryText)
                
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .foregroundColor(SemanticColors.tertiaryText)
                        
                        Text(String(localized: "library.childsWorld.loading"))
                            .font(.system(size: 12))
                            .foregroundColor(SemanticColors.tertiaryText)
                    }
                } else if hasError {
                    Text(String(localized: "library.childsWorld.error"))
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.tertiaryText)
                } else {
                    let totalInsights = insightCounts.values.reduce(0, +)
                    if totalInsights > 0 {
                        Text(String.localizedStringWithFormat(String(localized: "library.childsWorld.count %lld %lld"), totalInsights, insightCounts.count))
                            .font(.system(size: 12))
                            .foregroundColor(SemanticColors.tertiaryText)
                    } else {
                        Text(String(localized: "library.childsWorld.empty"))
                            .font(.system(size: 12))
                            .foregroundColor(SemanticColors.tertiaryText)
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onViewInsights) {
                    Text(String(localized: "library.childsWorld.button"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(SemanticColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isLoading || isRegenerating)
                
                Button(action: {
                    showingRegenerateConfirmation = true
                }) {
                    HStack(spacing: 6) {
                        if isRegenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(SemanticColors.primaryText)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .medium))
                        }
                        
                        Text(String(localized: "library.regenerate.button"))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(SemanticColors.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(SemanticColors.accentBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isLoading || isRegenerating)
                
                Spacer()
            }
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
        .onAppear {
            Task {
                await loadInsightCounts()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task {
                await loadInsightCounts()
            }
        }
        .confirmationDialog(String(localized: "library.regenerate.confirmation.title"), isPresented: $showingRegenerateConfirmation) {
            Button(String(localized: "library.regenerate.confirmation.action"), role: .destructive) {
                Task {
                    await regenerateInsights()
                }
            }
            Button(String(localized: "common.cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "library.regenerate.confirmation.message"))
        }
        .alert(String(localized: "library.regenerate.success.title"), isPresented: $showingRegenerateSuccess) {
            Button(String(localized: "common.ok")) { }
        } message: {
            Text(String(localized: "library.regenerate.success.message \(regenerateResultCounts.values.reduce(0, +))"))
        }
        .alert(String(localized: "library.regenerate.error.title"), isPresented: $showingRegenerateError) {
            Button(String(localized: "common.ok")) { }
        } message: {
            Text(regenerateErrorMessage.isEmpty ? String(localized: "library.regenerate.error.message") : regenerateErrorMessage)
        }
    }
    
    @MainActor
    private func loadInsightCounts() async {
        guard let familyId = familyId else {
            print("❌ No family ID available for YourChildsWorldCard")
            return
        }
        
        isLoading = true
        hasError = false
        
        do {
            insightCounts = try await ContextualInsightService.shared.getInsightCounts(familyId: familyId)
            print("✅ Loaded insight counts: \(insightCounts)")
        } catch {
            print("❌ Failed to load insight counts: \(error)")
            hasError = true
        }
        
        isLoading = false
    }
    
    @MainActor
    private func regenerateInsights() async {
        guard let familyId = familyId else {
            regenerateErrorMessage = String(localized: "library.regenerate.error.noFamily")
            showingRegenerateError = true
            return
        }
        
        // Get active API key from MultiProviderApiKeyService
        let apiKeyService = MultiProviderApiKeyService.shared
        guard let activeUserApiKey = try? await apiKeyService.getActiveApiKey(for: familyId),
              !activeUserApiKey.apiKey.isEmpty else {
            regenerateErrorMessage = String(localized: "library.regenerate.error.noApiKey")
            showingRegenerateError = true
            return
        }
        
        isRegenerating = true
        regenerateErrorMessage = ""
        
        do {
            let counts = try await ContextualInsightService.shared.regenerateAllContextualInsights(
                familyId: familyId,
                apiKey: activeUserApiKey.apiKey
            )
            
            regenerateResultCounts = counts
            
            // Refresh the insight counts display
            await loadInsightCounts()
            
            showingRegenerateSuccess = true
            
        } catch {
            print("❌ Error regenerating contextual insights: \(error)")
            
            // Provide more specific error messages
            if let contextError = error as? ContextualInsightError {
                switch contextError {
                case .invalidResponse:
                    regenerateErrorMessage = "Invalid response from the API. Please try again."
                case .noContent:
                    regenerateErrorMessage = "No content was returned from the API. Please check your situations have content."
                case .parsingError(let parseError):
                    regenerateErrorMessage = "Failed to process insights: \(parseError.localizedDescription)"
                case .databaseError(let dbError):
                    regenerateErrorMessage = "Database error: \(dbError.localizedDescription)"
                case .apiError(let statusCode):
                    regenerateErrorMessage = "API error (code: \(statusCode)). Please check your API key and try again."
                }
            } else {
                regenerateErrorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            }
            
            showingRegenerateError = true
        }
        
        isRegenerating = false
    }
}

#Preview {
    YourChildsWorldCard(familyId: "preview-family-id") {
        print("View insights tapped")
    }
    .padding()
    .background(SemanticColors.primaryBackground)
}