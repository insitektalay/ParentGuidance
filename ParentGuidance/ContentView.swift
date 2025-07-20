import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text(String(localized: "app.name"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.terracotta)
            
            Text(String(localized: "app.tagline"))
                .font(.headline)
                .foregroundColor(ColorPalette.navy)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.cream)
    }
}
