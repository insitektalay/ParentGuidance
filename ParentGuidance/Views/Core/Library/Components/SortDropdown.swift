//
//  SortDropdown.swift
//  ParentGuidance
//
//  Created by alex kerss on 04/07/2025.
//

import Foundation
import SwiftUI

struct SortDropdown: View {
    @ObservedObject var controller: LibraryViewController
    
    var body: some View {
        // Sort button - compact arrow only, no extra padding
        Button(action: {
            controller.toggleSortDropdown()
        }) {
            Image(systemName: controller.isShowingSortDropdown ? "chevron.up" : "chevron.down")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorPalette.white.opacity(0.8))
                .padding(8)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(ColorPalette.white.opacity(0.2), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Sort options: \(controller.selectedSort.displayName)")
        .accessibilityHint("Double tap to change how situations are sorted")
    }
}

struct SortDropdown_Previews: PreviewProvider {
    static var previews: some View {
        let mockController = LibraryViewController()
        
        VStack(spacing: 20) {
            SortDropdown(controller: mockController)
            
            // Preview with dropdown open
            SortDropdown(controller: {
                let controller = LibraryViewController()
                controller.isShowingSortDropdown = true
                return controller
            }())
        }
        .padding()
        .background(ColorPalette.navy)
    }
}
