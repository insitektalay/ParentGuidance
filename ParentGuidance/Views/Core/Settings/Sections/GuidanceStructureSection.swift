//
//  GuidanceStructureSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct GuidanceStructureSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var guidanceStructureSettings: GuidanceStructureSettings
    @ObservedObject var viewState: SettingsViewState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "settings.guidanceStructure.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(SemanticColors.primaryText)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                // Current mode status
                HStack(spacing: 8) {
                    Image(systemName: guidanceStructureSettings.currentMode.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(SemanticColors.accentBlue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "settings.guidanceStructure.activeMode"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(SemanticColors.primaryText)
                        
                        Text(guidanceStructureSettings.currentMode.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SemanticColors.accentBlue)
                    }
                    
                    Spacer()
                    
                    // Mode indicator badge
                    Text(guidanceStructureSettings.currentMode.sectionCount)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SemanticColors.accentBlue.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                // Mode description
                Text(guidanceStructureSettings.currentMode.description)
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.secondaryText)
                    .lineLimit(nil)
                
                // Mode selection cards
                VStack(spacing: 12) {
                    ForEach(GuidanceStructureMode.allCases, id: \.self) { mode in
                        GuidanceModeCard(
                            mode: mode,
                            isSelected: guidanceStructureSettings.currentMode == mode,
                            onSelect: {
                                guidanceStructureSettings.currentMode = mode
                            }
                        )
                    }
                }
                
                // Guidance Style selection
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "settings.guidanceStructure.style"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                        .padding(.top, 8)
                    
                    VStack(spacing: 8) {
                        // Warm & Practical toggle
                        HStack {
                            Text(String(localized: "settings.guidanceStructure.style.warmPractical"))
                                .font(.system(size: 14))
                                .foregroundColor(SemanticColors.primaryText)
                            
                            Spacer()
                            
                            Button(action: {
                                if guidanceStructureSettings.currentStyle != .warmPractical {
                                    guidanceStructureSettings.currentStyle = .warmPractical
                                }
                            }) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(guidanceStructureSettings.currentStyle == .warmPractical ? SemanticColors.accentBlue : SemanticColors.tertiaryText)
                                    .frame(width: 44, height: 24)
                                    .overlay(
                                        Circle()
                                            .fill(SemanticColors.primaryText)
                                            .frame(width: 20, height: 20)
                                            .offset(x: guidanceStructureSettings.currentStyle == .warmPractical ? 10 : -10)
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: guidanceStructureSettings.currentStyle)
                            }
                        }
                        
                        // Analytical & Scientific toggle
                        HStack {
                            Text(String(localized: "settings.guidanceStructure.style.analyticalScientific"))
                                .font(.system(size: 14))
                                .foregroundColor(SemanticColors.primaryText)
                            
                            Spacer()
                            
                            Button(action: {
                                if guidanceStructureSettings.currentStyle != .analyticalScientific {
                                    guidanceStructureSettings.currentStyle = .analyticalScientific
                                }
                            }) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(guidanceStructureSettings.currentStyle == .analyticalScientific ? SemanticColors.accentBlue : SemanticColors.tertiaryText)
                                    .frame(width: 44, height: 24)
                                    .overlay(
                                        Circle()
                                            .fill(SemanticColors.primaryText)
                                            .frame(width: 20, height: 20)
                                            .offset(x: guidanceStructureSettings.currentStyle == .analyticalScientific ? 10 : -10)
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: guidanceStructureSettings.currentStyle)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                // Chat Style Interface toggle
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "settings.guidanceStructure.chatStyle.section"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                        .padding(.top, 8)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "settings.guidanceStructure.chatStyle.title"))
                                .font(.system(size: 14))
                                .foregroundColor(SemanticColors.primaryText)
                            
                            Text(String(localized: "settings.guidanceStructure.chatStyle.description"))
                                .font(.system(size: 11))
                                .foregroundColor(SemanticColors.secondaryText)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            guidanceStructureSettings.toggleChatStyle()
                        }) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(guidanceStructureSettings.useChatStyleInterface ? SemanticColors.accentBlue : SemanticColors.tertiaryText)
                                .frame(width: 44, height: 24)
                                .overlay(
                                    Circle()
                                        .fill(SemanticColors.primaryText)
                                        .frame(width: 20, height: 20)
                                        .offset(x: guidanceStructureSettings.useChatStyleInterface ? 10 : -10)
                                )
                                .animation(.easeInOut(duration: 0.2), value: guidanceStructureSettings.useChatStyleInterface)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                // Psychologist's Notes integration
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "settings.guidanceStructure.psychologistNotes"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                        .padding(.top, 8)
                    
                    VStack(spacing: 8) {
                        // Child Context toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "settings.guidanceStructure.childContext.title"))
                                    .font(.system(size: 14))
                                    .foregroundColor(SemanticColors.primaryText)
                                
                                Text(String(localized: "settings.guidanceStructure.childContext.description"))
                                    .font(.system(size: 11))
                                    .foregroundColor(SemanticColors.secondaryText)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                guidanceStructureSettings.toggleChildContext()
                            }) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(guidanceStructureSettings.enableChildContext ? SemanticColors.accentBlue : SemanticColors.tertiaryText)
                                    .frame(width: 44, height: 24)
                                    .overlay(
                                        Circle()
                                            .fill(SemanticColors.primaryText)
                                            .frame(width: 20, height: 20)
                                            .offset(x: guidanceStructureSettings.enableChildContext ? 10 : -10)
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: guidanceStructureSettings.enableChildContext)
                            }
                        }
                        
                        // Key Insights toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "settings.guidanceStructure.keyInsights.title"))
                                    .font(.system(size: 14))
                                    .foregroundColor(SemanticColors.primaryText)
                                
                                Text(String(localized: "settings.guidanceStructure.keyInsights.description"))
                                    .font(.system(size: 11))
                                    .foregroundColor(SemanticColors.secondaryText)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                guidanceStructureSettings.toggleKeyInsights()
                            }) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(guidanceStructureSettings.enableKeyInsights ? SemanticColors.accentBlue : SemanticColors.tertiaryText)
                                    .frame(width: 44, height: 24)
                                    .overlay(
                                        Circle()
                                            .fill(SemanticColors.primaryText)
                                            .frame(width: 20, height: 20)
                                            .offset(x: guidanceStructureSettings.enableKeyInsights ? 10 : -10)
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: guidanceStructureSettings.enableKeyInsights)
                            }
                        }
                        
                        // Coping Strategies toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "settings.guidanceStructure.copingStrategies.title"))
                                    .font(.system(size: 14))
                                    .foregroundColor(SemanticColors.primaryText)
                                
                                Text(String(localized: "settings.guidanceStructure.copingStrategies.description"))
                                    .font(.system(size: 11))
                                    .foregroundColor(SemanticColors.secondaryText)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                guidanceStructureSettings.toggleCopingStrategies()
                            }) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(guidanceStructureSettings.enableCopingStrategies ? SemanticColors.accentBlue : SemanticColors.tertiaryText)
                                    .frame(width: 44, height: 24)
                                    .overlay(
                                        Circle()
                                            .fill(SemanticColors.primaryText)
                                            .frame(width: 20, height: 20)
                                            .offset(x: guidanceStructureSettings.enableCopingStrategies ? 10 : -10)
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: guidanceStructureSettings.enableCopingStrategies)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                // Mode benefits info
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "settings.guidanceStructure.benefits \(guidanceStructureSettings.currentMode.displayName)"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Text(guidanceStructureSettings.currentMode.benefits)
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.secondaryText)
                        .lineLimit(nil)
                }
                .padding(.top, 8)
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(String(localized: "settings.guidanceStructure.learnMore")) {
                        viewState.showingDocumentation = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SemanticColors.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(SemanticColors.accentBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button(String(localized: "settings.guidanceStructure.previewMode")) {
                        // TODO: Add preview functionality
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SemanticColors.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(SemanticColors.accent, lineWidth: 1)
                    )
                    
                    Spacer()
                }
                .padding(.top, 12)
            }
            .padding(16)
            .background(SemanticColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .if(colorScheme == .light) { view in
                view.cardShadow()
            }
            .padding(.horizontal, 16)
        }
    }
}
