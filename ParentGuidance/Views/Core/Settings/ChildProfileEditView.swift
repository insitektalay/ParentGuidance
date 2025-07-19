import SwiftUI

struct SettingsDatePicker: View {
    let label: String
    @Binding var date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(ColorPalette.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorPalette.terracotta.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct SettingsTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(ColorPalette.white.opacity(0.9))
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(ColorPalette.navy)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(ColorPalette.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorPalette.terracotta.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct ChildProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var childName: String = ""
    @State private var birthDate: Date = Date()
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showingError: Bool = false
    
    let child: Child
    let onSave: (String, Int?, String?) async -> Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section
                    VStack(spacing: 8) {
                        Text(String(localized: "childProfileEdit.title"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorPalette.white)
                            .multilineTextAlignment(.center)
                        
                        Text(String(localized: "childProfileEdit.subtitle"))
                            .font(.body)
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 24)
                    
                    // Form fields section
                    VStack(spacing: 24) {
                        SettingsTextField(
                            label: String(localized: "childProfileEdit.nameLabel"),
                            placeholder: String(localized: "childProfileEdit.namePlaceholder"),
                            text: $childName
                        )
                        
                        SettingsDatePicker(
                            label: String(localized: "childProfileEdit.birthDateLabel"),
                            date: $birthDate
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 100)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorPalette.navy)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                    .foregroundColor(ColorPalette.white.opacity(0.8))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSaving ? String(localized: "childProfileEdit.saving") : String(localized: "common.save")) {
                        Task {
                            await handleSave()
                        }
                    }
                    .foregroundColor(isValidForm ? ColorPalette.terracotta : ColorPalette.white.opacity(0.5))
                    .disabled(!isValidForm || isSaving)
                }
            }
        }
        .onAppear {
            loadChildData()
        }
        .alert(String(localized: "common.error.title"), isPresented: $showingError) {
            Button(String(localized: "common.ok")) {
                showingError = false
            }
        } message: {
            Text(errorMessage ?? String(localized: "childProfileEdit.errorSaving"))
        }
    }
    
    // MARK: - Form Validation
    
    private var isValidForm: Bool {
        !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Data Loading
    
    private func loadChildData() {
        childName = child.name ?? ""
        
        // Calculate birth date from age if available
        if let age = child.age, age > 0 {
            let calendar = Calendar.current
            // Calculate birth date more precisely by subtracting years and setting to beginning of year
            let currentYear = calendar.component(.year, from: Date())
            let birthYear = currentYear - age
            var dateComponents = DateComponents()
            dateComponents.year = birthYear
            dateComponents.month = 1
            dateComponents.day = 1
            birthDate = calendar.date(from: dateComponents) ?? Date()
        } else {
            // Default to a reasonable child birth date if no age is stored
            let calendar = Calendar.current
            birthDate = calendar.date(byAdding: .year, value: -5, to: Date()) ?? Date()
        }
    }
    
    // MARK: - Save Logic
    
    private func handleSave() async {
        guard isValidForm else { return }
        
        isSaving = true
        errorMessage = nil
        
        let trimmedName = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Calculate age from birth date
        let calendar = Calendar.current
        let age = calendar.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        
        let success = await onSave(trimmedName, age, nil)
        
        await MainActor.run {
            isSaving = false
            
            if success {
                dismiss()
            } else {
                errorMessage = String(localized: "childProfileEdit.saveFailure")
                showingError = true
            }
        }
    }
}

#Preview {
    ChildProfileEditView(
        child: Child(
            familyId: "test-family",
            name: "Test Child",
            age: 5,
            pronouns: "they/them"
        ),
        onSave: { name, age, pronouns in
            print("Save: \(name), age: \(age ?? 0), pronouns: \(pronouns ?? "none")")
            return true
        }
    )
}