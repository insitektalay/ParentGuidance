//
//  SearchFilterView.swift
//  ParentGuidance
//
//  Created by alex kerss on 04/07/2025.
//

import Foundation
import SwiftUI

struct SearchFilterView: View {
    @ObservedObject var controller: LibraryViewController
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DateFilter.allCases, id: \.self) { filter in
                    FilterButton(
                        title: filter.displayName,
                        icon: filter.sfSymbol,
                        isActive: controller.selectedDateFilter == filter,
                        badgeCount: controller.dateFilterCounts[filter],
                        onTap: {
                            controller.updateDateFilter(filter)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .accessibilityLabel(String(localized: "library.filter.date.title"))
        .accessibilityHint(String(localized: "library.filter.date.hint"))
    }
}

struct SearchFilterView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock controller for preview
        let mockController = LibraryViewController()
        
        SearchFilterView(controller: mockController)
            .padding()
            .background(ColorPalette.navy)
    }
}
