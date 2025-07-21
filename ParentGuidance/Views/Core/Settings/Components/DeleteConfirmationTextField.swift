//
//  DeleteConfirmationTextField.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct DeleteConfirmationTextField: View {
    @State private var confirmationText: String = ""
    let onConfirmed: () -> Void
    
    private var isValidConfirmation: Bool {
        confirmationText.uppercased() == "DELETE"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            TextField(String(localized: "settings.account.delete.placeholder"), text: $confirmationText)
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(ColorPalette.navy)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isValidConfirmation ? .red : ColorPalette.navy.opacity(0.3), lineWidth: 2)
                )
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
            
            Button(String(localized: "settings.account.delete.title")) {
                onConfirmed()
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(isValidConfirmation ? .red : .gray)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .disabled(!isValidConfirmation)
        }
    }
}
