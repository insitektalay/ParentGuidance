//
//  PsychologistNoteView.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct PsychologistNoteView: View {
    let familyId: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    @State private var notes: [PsychologistNote] = []
    @State private var isLoading = true
    @State private var hasError = false
    @State private var errorMessage = ""
    
    // Generation states
    @State private var isGeneratingContext = false
    @State private var isGeneratingTraits = false
    @State private var generationError: String?
    
    // Navigation
    @State private var selectedNote: PsychologistNote?
    @State private var showingNoteDetail = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .center, spacing: 12) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(ColorPalette.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Text(String(localized: "psychologistNote.view.title"))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(ColorPalette.white.opacity(0.9))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                // Content
                if isLoading {
                    loadingView
                } else if hasError {
                    errorView
                } else {
                    mainContentView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingNoteDetail) {
            if let selectedNote = selectedNote {
                PsychologistNoteDetailView(note: selectedNote)
            }
        }
        .onAppear {
            Task {
                await loadNotes()
            }
        }
        .refreshable {
            await loadNotes()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .foregroundColor(ColorPalette.white.opacity(0.8))
            
            Text(String(localized: "psychologistNote.loading"))
                .font(.system(size: 16))
                .foregroundColor(ColorPalette.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Text(String(localized: "psychologistNote.error.title"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(errorMessage)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button(String(localized: "common.retry")) {
                Task {
                    await loadNotes()
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(ColorPalette.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(ColorPalette.terracotta)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
    
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Generation Section
                generationSection
                
                // Existing Notes Section
                if !notes.isEmpty {
                    existingNotesSection
                } else {
                    emptyNotesSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
    
    private var generationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "psychologistNote.generate.title"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            Text(String(localized: "psychologistNote.generate.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.7))
            
            // Generation Error Alert
            if let generationError = generationError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text(generationError)
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.8))
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Generation Buttons
            VStack(spacing: 12) {
                generateButton(
                    title: String(localized: "psychologistNote.generate.context"),
                    subtitle: String(localized: "psychologistNote.generate.context.subtitle"),
                    isGenerating: isGeneratingContext,
                    noteType: .context
                )
                
                generateButton(
                    title: String(localized: "psychologistNote.generate.traits"),
                    subtitle: String(localized: "psychologistNote.generate.traits.subtitle"),
                    isGenerating: isGeneratingTraits,
                    noteType: .traits
                )
            }
        }
        .padding(16)
        .background(Color(red: 0.21, green: 0.22, blue: 0.33))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func generateButton(
        title: String,
        subtitle: String,
        isGenerating: Bool,
        noteType: PsychologistNoteType
    ) -> some View {
        Button {
            Task {
                await generateNote(type: noteType)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: noteType.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(ColorPalette.brightBlue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                }
                
                Spacer()
                
                if isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.terracotta)
                }
            }
            .padding(12)
            .background(ColorPalette.navy.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(isGenerating || isGeneratingContext || isGeneratingTraits)
    }
    
    private var existingNotesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "psychologistNote.existing.title"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            LazyVStack(spacing: 12) {
                ForEach(notes) { note in
                    noteRow(note)
                }
            }
        }
    }
    
    private func noteRow(_ note: PsychologistNote) -> some View {
        Button {
            selectedNote = note
            showingNoteDetail = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: note.noteType.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(ColorPalette.brightBlue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.displayTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                    
                    Text(note.formattedCreatedDate)
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.6))
                    
                    Text(note.previewContent)
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(ColorPalette.white.opacity(0.4))
            }
            .padding(12)
            .background(Color(red: 0.21, green: 0.22, blue: 0.33))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ColorPalette.white.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var emptyNotesSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(ColorPalette.white.opacity(0.3))
            
            Text(String(localized: "psychologistNote.empty.title"))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.8))
            
            Text(String(localized: "psychologistNote.empty.subtitle"))
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func loadNotes() async {
        isLoading = true
        hasError = false
        generationError = nil
        
        do {
            notes = try await PsychologistNoteService.shared.fetchPsychologistNotes(familyId: familyId)
            print("✅ Loaded \(notes.count) psychologist notes")
        } catch {
            print("❌ Failed to load psychologist notes: \(error)")
            hasError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    private func generateNote(type: PsychologistNoteType) async {
        // Clear previous errors
        generationError = nil
        
        // Set loading state
        if type == .context {
            isGeneratingContext = true
        } else {
            isGeneratingTraits = true
        }
        
        do {
            // Get API key from user profile
            guard let userId = appCoordinator.currentUserId else {
                throw PsychologistNoteError.generationFailed("No user ID available")
            }
            
            let userProfile = try await AuthService.shared.loadUserProfile(userId: userId)
            
            guard let apiKey = userProfile.userApiKey else {
                throw PsychologistNoteError.generationFailed("No API key configured")
            }
            
            // Generate the note
            let newNote = try await PsychologistNoteService.shared.generatePsychologistNote(
                familyId: familyId,
                childId: nil, // For now, generate family-wide notes
                noteType: type,
                apiKey: apiKey
            )
            
            // Add to notes list and refresh
            notes.insert(newNote, at: 0)
            print("✅ Generated \(type.rawValue) note successfully")
            
        } catch {
            print("❌ Failed to generate \(type.rawValue) note: \(error)")
            generationError = error.localizedDescription
        }
        
        // Clear loading state
        if type == .context {
            isGeneratingContext = false
        } else {
            isGeneratingTraits = false
        }
    }
}

#Preview {
    PsychologistNoteView(familyId: "preview-family-id")
        .environmentObject(AppCoordinator())
}