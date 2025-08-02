//
//  RelevantInsightsSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 01/08/2025.
//

import SwiftUI

struct RelevantInsightsSection: View {
    let insights: [RelevantInsight]
    @State private var isExpanded = true
    
    var body: some View {
        if !insights.isEmpty {
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
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SemanticColors.secondaryText)
                    }
                }
                
                if isExpanded {
                    // Group insights by type
                    let contextualInsights = insights.filter { $0.insightType == "contextual" }
                    let regulationInsights = insights.filter { $0.insightType == "regulation" }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Contextual insights section
                        if !contextualInsights.isEmpty {
                            insightTypeSection(
                                title: String(localized: "insights.relevant.contextual.header"),
                                icon: "house.fill",
                                insights: contextualInsights
                            )
                        }
                        
                        // Regulation insights section
                        if !regulationInsights.isEmpty {
                            insightTypeSection(
                                title: String(localized: "insights.relevant.regulation.header"),
                                icon: "brain.head.profile",
                                insights: regulationInsights
                            )
                        }
                        
                        if contextualInsights.isEmpty && regulationInsights.isEmpty {
                            Text(String(localized: "insights.relevant.empty"))
                                .font(.system(size: 14))
                                .foregroundColor(SemanticColors.secondaryText)
                                .italic()
                        }
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
    }
    
    @ViewBuilder
    private func insightTypeSection(
        title: String,
        icon: String,
        insights: [RelevantInsight]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SemanticColors.accent.opacity(0.8))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SemanticColors.secondaryText)
            }
            
            // Insights list
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SemanticColors.accent.opacity(0.7))
                            .padding(.top, 2)
                        
                        Text(insight.insightContent)
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.secondaryText)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, 8)
        }
    }
}

// MARK: - Loading State

struct RelevantInsightsLoadingView: View {
    var body: some View {
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
            
            // Loading content
            HStack(spacing: 8) {
                ProgressView()
                    .tint(SemanticColors.accent.opacity(0.7))
                    .scaleEffect(0.8)
                
                Text(String(localized: "insights.relevant.loading"))
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.secondaryText)
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
}

// MARK: - Empty State

struct RelevantInsightsEmptyView: View {
    let reason: EmptyReason
    
    enum EmptyReason {
        case noInsightsFound
        case noExistingInsights
        case processingError
        
        var title: String {
            switch self {
            case .noInsightsFound:
                return "No Relevant Insights"
            case .noExistingInsights:
                return "No Insights Available"
            case .processingError:
                return "Processing Error"
            }
        }
        
        var message: String {
            switch self {
            case .noInsightsFound:
                return "No existing insights were found to be relevant to this guidance."
            case .noExistingInsights:
                return "Create more situations to build up your insights knowledge base."
            case .processingError:
                return "There was an issue processing relevant insights. Check logs for details."
            }
        }
        
        var icon: String {
            switch self {
            case .noInsightsFound:
                return "lightbulb.slash"
            case .noExistingInsights:
                return "tray"
            case .processingError:
                return "exclamationmark.triangle"
            }
        }
    }
    
    var body: some View {
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
            
            // Empty state content
            HStack(spacing: 12) {
                Image(systemName: reason.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SemanticColors.tertiaryText)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reason.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.secondaryText)
                    
                    Text(reason.message)
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SemanticColors.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(SemanticColors.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Debug State

struct RelevantInsightsDebugView: View {
    let debugInfo: DebugInfo
    
    struct DebugInfo {
        let totalInsightsFound: Int
        let llmResponseLength: Int
        let selectedInsightsCount: Int
        let matchedInsightsCount: Int
        let processingTimeMs: Int?
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.2.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(SemanticColors.accent)
                
                Text("Relevant Insights (Debug)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
                
                Image(systemName: "ladybug")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SemanticColors.accentBlue)
            }
            
            // Debug content
            VStack(alignment: .leading, spacing: 8) {
                debugRow(title: "Total Insights Available", value: "\(debugInfo.totalInsightsFound)")
                debugRow(title: "LLM Response Length", value: "\(debugInfo.llmResponseLength) chars")
                debugRow(title: "Insights Selected by LLM", value: "\(debugInfo.selectedInsightsCount)")
                debugRow(title: "Successfully Matched", value: "\(debugInfo.matchedInsightsCount)")
                
                if let processingTime = debugInfo.processingTimeMs {
                    debugRow(title: "Processing Time", value: "\(processingTime)ms")
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SemanticColors.accentBlue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(SemanticColors.accentBlue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func debugRow(title: String, value: String) -> some View {
        HStack {
            Text(title + ":")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(SemanticColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(SemanticColors.accentBlue)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Success state
        RelevantInsightsSection(insights: [
            RelevantInsight(
                situationId: "test-situation",
                guidanceId: "test-guidance",
                insightType: "contextual",
                insightId: "test-1",
                insightContent: "Child prefers quiet environment for focus"
            ),
            RelevantInsight(
                situationId: "test-situation",
                guidanceId: "test-guidance", 
                insightType: "regulation",
                insightId: "test-2",
                insightContent: "Benefits from transition warnings before switching activities"
            )
        ])
        
        // Loading state
        RelevantInsightsLoadingView()
        
        // Empty states
        RelevantInsightsEmptyView(reason: .noInsightsFound)
        RelevantInsightsEmptyView(reason: .noExistingInsights)
        RelevantInsightsEmptyView(reason: .processingError)
        
        // Debug state
        RelevantInsightsDebugView(debugInfo: RelevantInsightsDebugView.DebugInfo(
            totalInsightsFound: 12,
            llmResponseLength: 450,
            selectedInsightsCount: 3,
            matchedInsightsCount: 2,
            processingTimeMs: 1250
        ))
    }
    .padding()
    .background(SemanticColors.primaryBackground)
}