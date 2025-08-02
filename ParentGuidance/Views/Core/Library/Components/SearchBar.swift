import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    @FocusState private var isSearchFocused: Bool
    
    init(searchText: Binding<String> = .constant("")) {
        self._searchText = searchText
    }
    
    var body: some View {
        HStack {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(SemanticColors.tertiaryText)
                .padding(.leading, 16)
            
            // Search text field
            TextField("Search situations...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(SemanticColors.primaryText)
                .focused($isSearchFocused)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.vertical, 10)
                .padding(.trailing, 16)
        }
        .background(SemanticColors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSearchFocused ? SemanticColors.accent.opacity(0.5) : SemanticColors.border,
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .cardShadow()
    }
}

#Preview {
    SearchBar()
        .padding()
        .background(SemanticColors.primaryBackground)
}