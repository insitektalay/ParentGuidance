//
//  ConfirmationDialog.swift
//  ParentGuidance
//
//  Created by alex kerss on 04/07/2025.
//

import SwiftUI

struct ConfirmationDialog: View {
    let title: String
    let message: String
    let destructiveButtonTitle: String
    let cancelButtonTitle: String
    let onDestruct: () -> Void
    let onCancel: () -> Void
    
    init(
        title: String,
        message: String,
        destructiveButtonTitle: String = "Delete",
        cancelButtonTitle: String = "Cancel",
        onDestruct: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.destructiveButtonTitle = destructiveButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
        self.onDestruct = onDestruct
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(SemanticColors.primaryText.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                // Destructive button
                Button(action: onDestruct) {
                    Text(destructiveButtonTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .accessibilityLabel(destructiveButtonTitle)
                .accessibilityHint("Confirms the destructive action")
                
                // Cancel button
                Button(action: onCancel) {
                    Text(cancelButtonTitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SemanticColors.primaryText)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(SemanticColors.cardBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(SemanticColors.primaryText.opacity(0.2), lineWidth: 1)
                        )
                }
                .accessibilityLabel(cancelButtonTitle)
                .accessibilityHint("Cancels the action")
            }
        }
        .padding(24)
        .background(SemanticColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: SemanticColors.primaryText.opacity(0.1), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 40)
    }
}

#Preview {
    ZStack {
        SemanticColors.primaryText.ignoresSafeArea()
        
        ConfirmationDialog(
            title: "Delete Situation",
            message: "Are you sure you want to delete this situation? This action cannot be undone.",
            onDestruct: {
                print("Delete confirmed")
            },
            onCancel: {
                print("Delete cancelled")
            }
        )
    }
}
