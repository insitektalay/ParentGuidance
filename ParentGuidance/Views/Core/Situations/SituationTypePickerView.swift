//
//  SituationTypePickerView.swift
//  ParentGuidance
//
//  Created by alex kerss on 24/07/2025.
//

import SwiftUI

struct SituationTypePickerView: View {
    @State private var selectedType: SituationType?
    let onTypeSelected: (SituationType) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(LocalizedStringKey("situation.picker.title"))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ColorPalette.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
            
            // List of situation types
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(SituationType.allCases, id: \.self) { type in
                        SituationTypeCard(
                            situationType: type,
                            isSelected: selectedType == type,
                            action: {
                                selectedType = type
                                // Small delay for visual feedback
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    onTypeSelected(type)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120) // Extra space for tab bar and safe area
            }
        }
        .background(ColorPalette.navy)
    }
}