import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            Text(String(localized: "app.name"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(SemanticColors.accent)
            
            Text(String(localized: "app.tagline"))
                .font(.headline)
                .foregroundColor(SemanticColors.primaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SemanticColors.primaryBackground)
        .if(colorScheme == .light) { view in
            view.cardShadow()
        }
    }
}
