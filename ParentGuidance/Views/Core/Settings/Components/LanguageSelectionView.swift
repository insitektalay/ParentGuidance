//
//  LanguageSelectionView.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct LanguageSelectionView: View {
    @Binding var selectedLanguage: String
    let onLanguageSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let supportedLanguages = LanguageDetectionService.shared.getSupportedLanguages()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "settings.language.title"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorPalette.white)
                        
                        Text(String(localized: "settings.language.description"))
                            .font(.body)
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Language options
                    LazyVStack(spacing: 8) {
                        ForEach(supportedLanguages, id: \.self) { languageCode in
                            LanguageOptionRow(
                                languageCode: languageCode,
                                languageName: LanguageDetectionService.shared.getLanguageName(for: languageCode),
                                isSelected: selectedLanguage == languageCode,
                                onTap: {
                                    onLanguageSelected(languageCode)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Family language info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "settings.language.familyNote.title"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ColorPalette.white)
                        
                        Text(String(localized: "settings.language.familyNote.description"))
                            .font(.system(size: 14))
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                            .lineSpacing(2)
                    }
                    .padding(16)
                    .background(ColorPalette.brightBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                }
                .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                    .foregroundColor(ColorPalette.white)
                }
            }
        }
    }
}
