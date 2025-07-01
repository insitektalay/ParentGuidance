import SwiftUI

struct CustomTextField: View {
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

struct CustomDatePicker: View {
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

struct ChildBasicsView: View {
    @State private var childName: String = ""
    @State private var birthDate: Date = Date()
    
    let onAddAnotherChild: (String, Date) -> Void
    let onContinue: (String, Date) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text("Tell us about your child")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorPalette.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Just the basics to get started")
                            .font(.body)
                            .foregroundColor(ColorPalette.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 80)
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 24) {
                        CustomTextField(
                            label: "What should we call your child?",
                            placeholder: "Child's name",
                            text: $childName
                        )
                        
                        CustomDatePicker(
                            label: "When was your child born?",
                            date: $birthDate
                        )
                        
                        Button(action: { onAddAnotherChild(childName, birthDate) }) {
                            Text("+ Add Another Child")
                                .font(.system(size: 16))
                                .foregroundColor(ColorPalette.terracotta)
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
                Text("You can add more details anytime in Settings")
                    .font(.system(size: 14))
                    .foregroundColor(ColorPalette.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                Button(action: { onContinue(childName, birthDate) }) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ColorPalette.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ColorPalette.terracotta)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.navy)
        .ignoresSafeArea()
    }
}

#Preview {
    ChildBasicsView(
        onAddAnotherChild: { _, _ in },
        onContinue: { _, _ in }
    )
}
