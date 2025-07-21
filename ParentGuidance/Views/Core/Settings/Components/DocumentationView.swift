//
//  DocumentationView.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct DocumentationView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(String(localized: "settings.helpSupport.documentation"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(ColorPalette.white)
                        .padding(.top)
                    
                    faqSection(
                        title: String(localized: "documentation.section.gettingStarted"),
                        items: [
                            ("How do I add my child's information?", "Go to Settings > Child Profile and tap 'Edit Profile' to update your child's name and date of birth."),
                            ("How do I get parenting guidance?", "Tap the 'New' tab and describe a parenting situation. The AI will provide personalized guidance based on your input."),
                            ("What are Foundation Tools?", "Foundation Tools are evidence-based parenting frameworks recommended by our AI based on your situations and needs.")
                        ]
                    )
                    
                    faqSection(
                        title: String(localized: "documentation.section.usingApp"),
                        items: [
                            ("How do I save a situation for later?", "Tap the heart icon on any situation in your Library to mark it as a favorite for easy access."),
                            ("Can I export my data?", "Yes! Go to Settings > Privacy & Data > 'Export My Data' to receive all your information via email."),
                            ("How do I set up a parenting framework?", "Select multiple related situations in your Library and tap 'Set Up Framework' to get AI-generated framework recommendations.")
                        ]
                    )
                    
                    faqSection(
                        title: String(localized: "documentation.section.accountApi"),
                        items: [
                            ("What's the difference between plans?", "Subscription plans include AI processing, while 'Bring Your Own API' lets you use your personal OpenAI API key."),
                            ("How do I add my OpenAI API key?", "If you selected 'Bring Your Own API', go to Settings > Account > 'Manage API Key' to add your key."),
                            ("Is my data secure?", "Yes, all data is encrypted and securely stored. You can export or delete your data anytime in Settings.")
                        ]
                    )
                    
                    faqSection(
                        title: String(localized: "documentation.section.troubleshooting"),
                        items: [
                            ("The app isn't responding correctly", "Try closing and reopening the app. If issues persist, contact support with your device and app version."),
                            ("I can't see my situations", "Check your internet connection. Your situations are synced to the cloud and require internet access."),
                            ("Framework recommendations aren't appearing", "Frameworks are generated based on multiple related situations. Try adding more situations to your Library first.")
                        ]
                    )
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
    
    private func faqSection(title: String, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.white)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    faqItem(question: item.0, answer: item.1)
                }
            }
        }
    }
    
    private func faqItem(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white)
            
            Text(answer)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.8))
                .lineSpacing(2)
        }
        .padding(16)
        .background(ColorPalette.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}