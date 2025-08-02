//
//  PsychologistNoteDetailView.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct PsychologistNoteDetailView: View {
    let note: PsychologistNote
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteConfirmation = false
    @State private var showingShareSheet = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    
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
                            .foregroundColor(SemanticColors.primaryText)
                    }
                    
                    Spacer()
                    
                    Text(note.displayTitle)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(SemanticColors.primaryText)
                    
                    Spacer()
                    
                    // Share and Delete buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundColor(SemanticColors.secondaryText)
                        }
                        
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .disabled(isDeleting)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Metadata Section
                        metadataSection
                        
                        // Note Content
                        noteContentSection
                        
                        // Error Section (if any)
                        if let deleteError = deleteError {
                            errorSection(deleteError)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SemanticColors.primaryBackground)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingShareSheet) {
            ActivityViewController(activityItems: [shareContent])
        }
        .confirmationDialog(
            String(localized: "psychologistNote.delete.confirm.title"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "psychologistNote.delete.confirm.action"), role: .destructive) {
                Task {
                    await deleteNote()
                }
            }
            
            Button(String(localized: "common.cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "psychologistNote.delete.confirm.message"))
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "psychologistNote.detail.metadata"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(SemanticColors.primaryText)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: note.noteType.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.accentBlue)
                    
                    Text(String(localized: "psychologistNote.detail.type"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.secondaryText)
                    
                    Spacer()
                    
                    Text(note.displayTitle)
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.accentBlue)
                    
                    Text(String(localized: "psychologistNote.detail.created"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.secondaryText)
                    
                    Spacer()
                    
                    Text(note.formattedCreatedDate)
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                }
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.accentBlue)
                    
                    Text(String(localized: "psychologistNote.detail.sources"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.secondaryText)
                    
                    Spacer()
                    
                    Text(note.sourceDataSummary)
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.secondaryText)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(16)
        .background(SemanticColors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SemanticColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var noteContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "psychologistNote.detail.content"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(SemanticColors.primaryText)
            
            Text(note.content)
                .font(.system(size: 15, weight: .regular))
                .lineSpacing(4)
                .foregroundColor(SemanticColors.secondaryText)
                .textSelection(.enabled)
        }
        .padding(16)
        .background(SemanticColors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SemanticColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func errorSection(_ error: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.secondaryText)
        }
        .padding(12)
        .background(Color.red.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var shareContent: String {
        let header = "\(note.displayTitle)\n\(String(localized: "psychologistNote.detail.created")): \(note.formattedCreatedDate)\n\n"
        let content = note.content
        let footer = "\n\n\(String(localized: "psychologistNote.share.footer"))"
        
        return header + content + footer
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func deleteNote() async {
        isDeleting = true
        deleteError = nil
        
        do {
            try await PsychologistNoteService.shared.deletePsychologistNote(noteId: note.id)
            print("✅ Deleted psychologist note successfully")
            
            // Dismiss the detail view after successful deletion
            dismiss()
            
        } catch {
            print("❌ Failed to delete psychologist note: \(error)")
            deleteError = error.localizedDescription
        }
        
        isDeleting = false
    }
}

// MARK: - ActivityViewController for Sharing

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    let sampleNote = PsychologistNote(
        familyId: "sample-family-id",
        childId: nil,
        noteType: .context,
        content: "This is a sample psychologist note content that would be much longer in practice and contain detailed insights about the child's development and behavioral patterns. It might span multiple paragraphs and include various observations and recommendations.",
        sourceDataSummary: "Based on 15 contextual insights across 8 categories"
    )
    
    return PsychologistNoteDetailView(note: sampleNote)
}