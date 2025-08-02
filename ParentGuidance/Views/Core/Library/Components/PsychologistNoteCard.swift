//
//  PsychologistNoteCard.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct PsychologistNoteCard: View {
    let familyId: String?
    let onViewNotes: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var noteCount: Int = 0
    @State private var isLoading: Bool = false
    @State private var hasError: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(SemanticColors.accentBlue)
                
                Text(String(localized: "library.psychologistNote.title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SemanticColors.primaryText)
                
                Spacer()
            }
            
            // Description and note count
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "library.psychologistNote.subtitle"))
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.secondaryText)
                
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .foregroundColor(SemanticColors.tertiaryText)
                        
                        Text(String(localized: "library.psychologistNote.loading"))
                            .font(.system(size: 12))
                            .foregroundColor(SemanticColors.tertiaryText)
                    }
                } else if hasError {
                    Text(String(localized: "library.psychologistNote.error"))
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.tertiaryText)
                } else {
                    if noteCount > 0 {
                        Text(String.localizedStringWithFormat(String(localized: "library.psychologistNote.count"), noteCount))
                            .font(.system(size: 12))
                            .foregroundColor(SemanticColors.tertiaryText)
                    } else {
                        Text(String(localized: "library.psychologistNote.empty"))
                            .font(.system(size: 12))
                            .foregroundColor(SemanticColors.tertiaryText)
                    }
                }
            }
            
            // Action button
            HStack(spacing: 12) {
                Button(action: onViewNotes) {
                    Text(noteCount > 0 ? 
                         String(localized: "library.psychologistNote.button.view") : 
                         String(localized: "library.psychologistNote.button.generate"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(SemanticColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isLoading)
                
                Spacer()
            }
        }
        .padding(16)
        .background(SemanticColors.cardBackground) // #363853 equivalent
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SemanticColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .if(colorScheme == .light) { view in
            view.cardShadow()
        }
        .onAppear {
            Task {
                await loadNoteCount()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task {
                await loadNoteCount()
            }
        }
    }
    
    @MainActor
    private func loadNoteCount() async {
        guard let familyId = familyId else {
            print("❌ No family ID available for PsychologistNoteCard")
            return
        }
        
        isLoading = true
        hasError = false
        
        do {
            let notes = try await PsychologistNoteService.shared.fetchPsychologistNotes(familyId: familyId)
            noteCount = notes.count
            print("✅ Loaded \(noteCount) psychologist notes")
        } catch {
            print("❌ Failed to load psychologist note count: \(error)")
            hasError = true
        }
        
        isLoading = false
    }
}

#Preview {
    PsychologistNoteCard(familyId: "preview-family-id") {
        print("View notes tapped")
    }
    .padding()
    .background(SemanticColors.primaryBackground)
}