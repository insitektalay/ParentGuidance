//
//  DeleteAccountConfirmationView.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct DeleteAccountConfirmationView: View {
    let step: Int
    let isDeleting: Bool
    let onNextStep: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            // Step-specific content
            switch step {
            case 0:
                firstStepContent
            case 1:
                secondStepContent
            case 2:
                finalStepContent
            default:
                firstStepContent
            }
        }
        .padding(32)
        .background(ColorPalette.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }
    
    private var firstStepContent: some View {
        VStack(spacing: 16) {
            Text(String(localized: "settings.account.delete.title"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.navy)
            
            Text(String(localized: "settings.account.delete.warning"))
                .font(.body)
                .foregroundColor(ColorPalette.navy.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.crop.circle")
                    Text(String(localized: "settings.account.delete.item.profile"))
                }
                HStack {
                    Image(systemName: "figure.child")
                    Text(String(localized: "settings.account.delete.item.children"))
                }
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text(String(localized: "settings.account.delete.item.history"))
                }
                HStack {
                    Image(systemName: "chart.bar.doc.horizontal")
                    Text(String(localized: "settings.account.delete.item.frameworks"))
                }
            }
            .font(.system(size: 14))
            .foregroundColor(ColorPalette.navy.opacity(0.7))
            
            HStack(spacing: 16) {
                Button(String(localized: "common.button.cancel")) {
                    onCancel()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.navy)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorPalette.navy, lineWidth: 1)
                )
                
                Button(String(localized: "common.button.continue")) {
                    onNextStep()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.red)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var secondStepContent: some View {
        VStack(spacing: 16) {
            Text(String(localized: "settings.account.delete.confirm.title"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.navy)
            
            Text(String(localized: "settings.account.delete.confirm.warning"))
                .font(.body)
                .foregroundColor(ColorPalette.navy.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Text(String(localized: "settings.account.delete.confirm.permanent"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button(String(localized: "common.button.back")) {
                    onCancel()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorPalette.navy)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorPalette.navy, lineWidth: 1)
                )
                
                Button(String(localized: "common.button.understand")) {
                    onNextStep()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.red)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var finalStepContent: some View {
        VStack(spacing: 16) {
            Text(String(localized: "settings.account.delete.final.title"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Text(String(localized: "settings.account.delete.final.instruction"))
                .font(.body)
                .foregroundColor(ColorPalette.navy.opacity(0.8))
                .multilineTextAlignment(.center)
            
            if isDeleting {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(String(localized: "settings.account.delete.deleting"))
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.navy.opacity(0.7))
                }
                .padding(.vertical)
            } else {
                VStack(spacing: 16) {
                    DeleteConfirmationTextField(onConfirmed: onDelete)
                    
                    Button(String(localized: "common.button.cancel")) {
                        onCancel()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ColorPalette.navy)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ColorPalette.navy, lineWidth: 1)
                    )
                }
            }
        }
    }
}
