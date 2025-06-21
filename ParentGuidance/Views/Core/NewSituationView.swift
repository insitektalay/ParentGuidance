import SwiftUI

struct NewSituationView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Main situation input screen state
            SituationInputIdleView(
                childName: "Alex",
                onStartRecording: {
                    // handle start recording
                },
                onSendMessage: {
                    // handle send
                }
            )
        }
        .background(ColorPalette.navy)
        
    }
}

