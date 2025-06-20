import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("ParentGuidance")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.terracotta)
            
            Text("Your parenting co-pilot")
                .font(.headline)
                .foregroundColor(ColorPalette.navy)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.cream)
    }
}
