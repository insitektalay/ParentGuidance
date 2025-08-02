//
//  LibraryHeaderView.swift
//  ParentGuidance
//
//  Created by alex kerss on 04/07/2025.
//

import Foundation
import SwiftUI

struct LibraryHeaderView: View {
    @ObservedObject var controller: LibraryViewController
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Search bar
            SearchBar(searchText: $controller.searchQuery)
                .padding(.horizontal, 16)
            
            // Filter and sort row
            HStack(spacing: 8) {
                // Date filter buttons (takes most space)
                SearchFilterView(controller: controller)
                
                // Sort dropdown button only 
                Button(action: {
                    controller.toggleSortDropdown()
                }) {
                    Image(systemName: controller.isShowingSortDropdown ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.secondaryText)
                        .padding(8)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(SemanticColors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 16)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "library.searchAndFilters"))
    }
}

struct LibraryHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        let mockController = LibraryViewController()
        
        VStack(spacing: 20) {
            LibraryHeaderView(controller: mockController)
            
            // Preview with dropdown open
            LibraryHeaderView(controller: {
                let controller = LibraryViewController()
                controller.isShowingSortDropdown = true
                return controller
            }())
        }
        .padding()
        .background(SemanticColors.primaryBackground)
    }
}
