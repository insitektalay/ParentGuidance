import SwiftUI

struct ChildProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var childName: String = ""
    @State private var childAge: String = ""
    @State private var childPronouns: String = ""
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
                        Text("Edit Child Profile")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorPalette.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Update your child's basic information")
                            .font(.body)
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 24)
                    
                    // Form fields section
                    VStack(spacing: 24) {
                        CustomTextField(
                            label: "Child's Name",
                            placeholder: "Enter name",
                            text: $childName
                        )
                        
                        CustomTextField(
                            label: "Age (years)",
                            placeholder: "Enter age",
                            text: $childAge
                        )
                        .keyboardType(.numberPad)
                        
                        CustomTextField(
                            label: "Pronouns (optional)",
                            placeholder: "e.g., they/them, she/her, he/him",
                            text: $childPronouns
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
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ColorPalette.white.opacity(0.8))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSaving ? "Saving..." : "Save") {
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
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
            }
        } message: {
            Text(errorMessage ?? "An error occurred while saving")
        }
    }
    
    // MARK: - Form Validation
    
    private var isValidForm: Bool {
        !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (childAge.isEmpty || (Int(childAge) != nil && Int(childAge)! >= 0 && Int(childAge)! <= 18))
    }
    
    // MARK: - Data Loading
    
    private func loadChildData() {
        childName = child.name ?? ""
        childAge = child.age != nil ? String(child.age!) : ""
        childPronouns = child.pronouns ?? ""
    }
    
    // MARK: - Save Logic
    
    private func handleSave() async {
        guard isValidForm else { return }
        
        isSaving = true
        errorMessage = nil
        
        let trimmedName = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        let age = childAge.isEmpty ? nil : Int(childAge)
        let pronouns = childPronouns.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : childPronouns.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let success = await onSave(trimmedName, age, pronouns)
        
        await MainActor.run {
            isSaving = false
            
            if success {
                dismiss()
            } else {
                errorMessage = "Failed to save child profile. Please try again."
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