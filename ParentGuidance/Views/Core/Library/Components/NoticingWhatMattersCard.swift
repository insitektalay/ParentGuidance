//
//  NoticingWhatMattersCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 18/07/2025.
//

import SwiftUI

struct NoticingWhatMattersCard: View {
    let familyId: String?
    let onViewInsights: () -> Void
    
    @State private var insightCounts: [RegulationCategory: Int] = [:]
    @State private var isLoading: Bool = false
    @State private var hasError: Bool = false
    @State private var isRegenerating: Bool = false
    @State private var showingRegenerateConfirmation: Bool = false
    @State private var showingRegenerateSuccess: Bool = false
    @State private var showingRegenerateError: Bool = false
    @State private var regenerateErrorMessage: String = ""
    @State private var regenerateResultCounts: (emotional: Int, attention: Int, flexibility: Int, coping: Int) = (0, 0, 0, 0)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20))
                    .foregroundColor(ColorPalette.brightBlue)
                
                Text(String(localized: "library.noticingWhatMatters.title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ColorPalette.white)
                
                Spacer()
            }
            
            // Description and insight count
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "library.noticingWhatMatters.subtitle"))
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.white.opacity(0.8))
                
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                        
                        Text(String(localized: "library.noticingWhatMatters.loading"))
                            .font(.system(size: 12))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                    }
                } else if hasError {
                    Text(String(localized: "error.loading.insights"))
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                } else {
                    let totalInsights = insightCounts.values.reduce(0, +)
                    if totalInsights > 0 {
                        Text(String(localized: "library.noticingWhatMatters.insightCount", defaultValue: "\(totalInsights) insights across \(insightCounts.count) categories"))
                            .font(.system(size: 12))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                    } else {
                        Text("No insights collected yet")
                            .font(.system(size: 12))
                            .foregroundColor(ColorPalette.white.opacity(0.6))
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onViewInsights) {
                    Text(String(localized: "library.childsWorld.button"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(ColorPalette.terracotta)
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
                                .foregroundColor(ColorPalette.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .medium))
                        }
                        
                        Text(String(localized: "library.regenerate.button"))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(ColorPalette.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(ColorPalette.brightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isLoading || isRegenerating)
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(red: 0.21, green: 0.22, blue: 0.33)) // #363853 equivalent
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            loadInsightCounts()
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
            Text(String(localized: "library.regenerate.success.message \(regenerateResultCounts.emotional + regenerateResultCounts.attention + regenerateResultCounts.flexibility + regenerateResultCounts.coping)"))
        }
        .alert(String(localized: "library.regenerate.error.title"), isPresented: $showingRegenerateError) {
            Button(String(localized: "common.ok")) { }
        } message: {
            Text(regenerateErrorMessage.isEmpty ? String(localized: "library.regenerate.error.message") : regenerateErrorMessage)
        }
    }
    
    private func loadInsightCounts() {
        guard let familyId = familyId else {
            hasError = true
            return
        }
        
        isLoading = true
        hasError = false
        
        Task {
            do {
                let counts = try await ContextualInsightService.shared.getRegulationInsightCounts(familyId: familyId)
                
                await MainActor.run {
                    self.insightCounts = counts
                    self.isLoading = false
                }
            } catch {
                print("❌ Error loading regulation insight counts: \(error)")
                await MainActor.run {
                    self.hasError = true
                    self.isLoading = false
                }
            }
        }
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
            let counts = try await ContextualInsightService.shared.regenerateAllRegulationInsights(
                familyId: familyId,
                apiKey: activeUserApiKey.apiKey
            )
            
            regenerateResultCounts = counts
            
            // Refresh the insight counts display
            loadInsightCounts()
            
            showingRegenerateSuccess = true
            
        } catch {
            print("❌ Error regenerating regulation insights: \(error)")
            
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
