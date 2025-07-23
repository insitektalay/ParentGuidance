//
//  GuidanceStructureSection.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct GuidanceStructureSection: View {
    @ObservedObject var guidanceStructureSettings: GuidanceStructureSettings
    @ObservedObject var viewState: SettingsViewState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "settings.guidanceStructure.title"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ColorPalette.white)
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 16) {
                // Current mode status
                HStack(spacing: 8) {
                    Image(systemName: guidanceStructureSettings.currentMode.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.brightBlue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "settings.guidanceStructure.activeMode"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ColorPalette.white)
                        
                        Text(guidanceStructureSettings.currentMode.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ColorPalette.brightBlue)
                    }
                    
                    Spacer()
                    
                    // Mode indicator badge
                    Text(guidanceStructureSettings.currentMode.sectionCount)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ColorPalette.brightBlue.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                // Mode description
                Text(guidanceStructureSettings.currentMode.description)
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.white.opacity(0.8))
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
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                        .padding(.top, 8)
                    
                    VStack(spacing: 8) {
                        // Warm & Practical toggle
                        HStack {
                            Text(String(localized: "settings.guidanceStructure.style.warmPractical"))
                                .font(.system(size: 14))
                                .foregroundColor(ColorPalette.white)
                            
                            Spacer()
                            
                            Button(action: {
                                if guidanceStructureSettings.currentStyle != .warmPractical {
                                    guidanceStructureSettings.currentStyle = .warmPractical
                                }
                            }) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(guidanceStructureSettings.currentStyle == .warmPractical ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.3))
                                    .frame(width: 44, height: 24)
                                    .overlay(
                                        Circle()
                                            .fill(ColorPalette.white)
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
                                .foregroundColor(ColorPalette.white)
                            
                            Spacer()
                            
                            Button(action: {
                                if guidanceStructureSettings.currentStyle != .analyticalScientific {
                                    guidanceStructureSettings.currentStyle = .analyticalScientific
                                }
                            }) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(guidanceStructureSettings.currentStyle == .analyticalScientific ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.3))
                                    .frame(width: 44, height: 24)
                                    .overlay(
                                        Circle()
                                            .fill(ColorPalette.white)
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
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                        .padding(.top, 8)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "settings.guidanceStructure.chatStyle.title"))
                                .font(.system(size: 14))
                                .foregroundColor(ColorPalette.white)
                            
                            Text(String(localized: "settings.guidanceStructure.chatStyle.description"))
                                .font(.system(size: 11))
                                .foregroundColor(ColorPalette.white.opacity(0.7))
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            guidanceStructureSettings.toggleChatStyle()
                        }) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(guidanceStructureSettings.useChatStyleInterface ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.3))
                                .frame(width: 44, height: 24)
                                .overlay(
                                    Circle()
                                        .fill(ColorPalette.white)
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
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                        .padding(.top, 8)
                    
                    VStack(spacing: 8) {
                        // Child Context toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "settings.guidanceStructure.childContext.title"))
                                    .font(.system(size: 14))
                                    .foregroundColor(ColorPalette.white)
                                
                                Text(String(localized: "settings.guidanceStructure.childContext.description"))
                                    .font(.system(size: 11))
                                    .foregroundColor(ColorPalette.white.opacity(0.7))
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                guidanceStructureSettings.toggleChildContext()
                            }) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(guidanceStructureSettings.enableChildContext ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.3))
                                    .frame(width: 44, height: 24)
                                    .overlay(
                                        Circle()
                                            .fill(ColorPalette.white)
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
                                    .foregroundColor(ColorPalette.white)
                                
                                Text(String(localized: "settings.guidanceStructure.keyInsights.description"))
                                    .font(.system(size: 11))
                                    .foregroundColor(ColorPalette.white.opacity(0.7))
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                guidanceStructureSettings.toggleKeyInsights()
                            }) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(guidanceStructureSettings.enableKeyInsights ? ColorPalette.brightBlue : ColorPalette.white.opacity(0.3))
                                    .frame(width: 44, height: 24)
                                    .overlay(
                                        Circle()
                                            .fill(ColorPalette.white)
                                            .frame(width: 20, height: 20)
                                            .offset(x: guidanceStructureSettings.enableKeyInsights ? 10 : -10)
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: guidanceStructureSettings.enableKeyInsights)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                // Mode benefits info
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "settings.guidanceStructure.benefits \(guidanceStructureSettings.currentMode.displayName)"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Text(guidanceStructureSettings.currentMode.benefits)
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                        .lineLimit(nil)
                }
                .padding(.top, 8)
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(String(localized: "settings.guidanceStructure.learnMore")) {
                        viewState.showingDocumentation = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorPalette.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(ColorPalette.brightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button(String(localized: "settings.guidanceStructure.previewMode")) {
                        // TODO: Add preview functionality
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorPalette.terracotta)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ColorPalette.terracotta, lineWidth: 1)
                    )
                    
                    Spacer()
                }
                .padding(.top, 12)
            }
            .padding(16)
            .background(ColorPalette.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }
}
