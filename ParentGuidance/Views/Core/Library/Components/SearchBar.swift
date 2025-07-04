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
                .foregroundColor(ColorPalette.white.opacity(0.5))
                .padding(.leading, 16)
            
            // Search text field
            TextField("Search situations...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(ColorPalette.white)
                .focused($isSearchFocused)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.vertical, 10)
                .padding(.trailing, 16)
        }
        .background(Color(red: 0.21, green: 0.22, blue: 0.33)) // #363853 equivalent
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSearchFocused ? ColorPalette.terracotta.opacity(0.5) : ColorPalette.white.opacity(0.1),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SearchBar()
        .padding()
        .background(ColorPalette.navy)
}