import SwiftUI

struct CustomTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.secondaryText)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(SemanticColors.primaryBackground)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(SemanticColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(SemanticColors.accent.opacity(0.3), lineWidth: 1)
                )
                .if(colorScheme == .light) { view in view.cardShadow() }
        }
    }
}

struct CustomDatePicker: View {
    let label: String
    @Binding var date: Date
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.secondaryText)
            
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(SemanticColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(SemanticColors.accent.opacity(0.3), lineWidth: 1)
                )
                .if(colorScheme == .light) { view in view.cardShadow() }
        }
    }
}

struct ChildBasicsView: View {
    @State private var childName: String = ""
    @State private var birthDate: Date = Date()
    
    let onAddAnotherChild: (String, Date) -> Void
    let onContinue: (String, Date) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text(String(localized: "childBasics.title"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(SemanticColors.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text(String(localized: "childBasics.subtitle"))
                            .font(.body)
                            .foregroundColor(SemanticColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 80)
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 24) {
                        CustomTextField(
                            label: String(localized: "childBasics.nameLabel"),
                            placeholder: String(localized: "childBasics.namePlaceholder"),
                            text: $childName
                        )
                        
                        CustomDatePicker(
                            label: String(localized: "childBasics.birthDateLabel"),
                            date: $birthDate
                        )
                        
                        Button(action: { onAddAnotherChild(childName, birthDate) }) {
                            Text(String(localized: "childBasics.addAnother"))
                                .font(.system(size: 16))
                                .foregroundColor(SemanticColors.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 150)
                }
            }
            
            VStack(spacing: 16) {
                Text(String(localized: "childBasics.moreDetailsHint"))
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.tertiaryText)
                    .multilineTextAlignment(.center)
                
                Button(action: { onContinue(childName, birthDate) }) {
                    Text(String(localized: "childBasics.continue"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(SemanticColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .if(colorScheme == .light) { view in view.cardShadow() }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SemanticColors.primaryBackground)
        .ignoresSafeArea()
    }
}

#Preview {
    ChildBasicsView(
        onAddAnotherChild: { _, _ in },
        onContinue: { _, _ in }
    )
}
