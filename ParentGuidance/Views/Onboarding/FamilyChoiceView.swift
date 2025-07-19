//
//  FamilyChoiceView.swift
//  ParentGuidance
//
//  Created by alex kerss on 19/07/2025.
//

import SwiftUI

struct FamilyChoiceView: View {
    let onCreateFamily: () -> Void
    let onJoinFamily: () -> Void
    let onBackTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Text(String(localized: "onboarding.familyChoice.title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(ColorPalette.navy)
                    .multilineTextAlignment(.center)
                
                Text(String(localized: "onboarding.familyChoice.subtitle"))
                    .font(.body)
                    .foregroundColor(ColorPalette.navy)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 60)
            .padding(.bottom, 60)
            
            Spacer()
            
            // Choice Cards
            VStack(spacing: 20) {
                // Create New Family Card
                FamilyChoiceCard(
                    icon: "house.fill",
                    title: String(localized: "onboarding.familyChoice.createFamily.title"),
                    description: String(localized: "onboarding.familyChoice.createFamily.description"),
                    buttonText: String(localized: "onboarding.familyChoice.createFamily.button"),
                    buttonColor: ColorPalette.brightBlue,
                    action: onCreateFamily
                )
                
                // Join Existing Family Card
                FamilyChoiceCard(
                    icon: "person.2.fill",
                    title: String(localized: "onboarding.familyChoice.joinFamily.title"),
                    description: String(localized: "onboarding.familyChoice.joinFamily.description"),
                    buttonText: String(localized: "onboarding.familyChoice.joinFamily.button"),
                    buttonColor: ColorPalette.terracotta,
                    action: onJoinFamily
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Back Button
            HStack {
                Button(action: onBackTapped) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text(String(localized: "onboarding.button.back"))
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(ColorPalette.navy)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(ColorPalette.cream)
        .ignoresSafeArea()
    }
}

struct FamilyChoiceCard: View {
    let icon: String
    let title: String
    let description: String
    let buttonText: String
    let buttonColor: Color
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(buttonColor)
            
            // Content
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorPalette.navy)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(ColorPalette.navy)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Action Button
            Button(action: action) {
                Text(buttonText)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(buttonColor)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    FamilyChoiceView(
        onCreateFamily: {},
        onJoinFamily: {},
        onBackTapped: {}
    )
}
