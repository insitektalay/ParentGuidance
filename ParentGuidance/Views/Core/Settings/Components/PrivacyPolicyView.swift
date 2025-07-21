//
//  PrivacyPolicyView.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(String(localized: "settings.privacyData.privacyPolicy"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(ColorPalette.white)
                        .padding(.top)
                    
                    privacySection(
                        title: String(localized: "privacy.section.dataCollection"),
                        content: "ParentGuidance collects only the information necessary to provide our parenting guidance service, including your child's basic information, parenting situations you share, and AI-generated guidance responses."
                    )
                    
                    privacySection(
                        title: String(localized: "privacy.section.dataUsage"),
                        content: "Your data is used exclusively to provide personalized parenting guidance through AI analysis. We do not sell, share, or use your information for advertising purposes."
                    )
                    
                    privacySection(
                        title: String(localized: "privacy.section.dataSecurity"),
                        content: "All data is securely stored using industry-standard encryption. You maintain full control over your data and can export or delete it at any time through the Settings."
                    )
                    
                    privacySection(
                        title: String(localized: "privacy.section.yourRights"),
                        content: "You have the right to access, export, correct, or delete your personal data. Use the 'Export My Data' feature to download all your information or 'Delete Account' to permanently remove all data."
                    )
                    
                    privacySection(
                        title: String(localized: "privacy.section.aiProcessing"),
                        content: "Situations you share are processed by AI to generate guidance. If you provide your own OpenAI API key, your data is processed directly through OpenAI's services according to their privacy policy."
                    )
                    
                    privacySection(
                        title: String(localized: "privacy.section.contact"),
                        content: "For privacy-related questions or concerns, please contact us through the Support section in Settings."
                    )
                    
                    Text(String(localized: "settings.privacyData.lastUpdated"))
                        .font(.caption)
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                        .padding(.top, 24)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.button.done")) {
                        dismiss()
                    }
                    .foregroundColor(ColorPalette.white)
                }
            }
        }
    }
    
    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.white)
            
            Text(content)
                .font(.body)
                .foregroundColor(ColorPalette.white.opacity(0.8))
                .lineSpacing(4)
        }
    }
}
