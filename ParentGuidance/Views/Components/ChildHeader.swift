import SwiftUI

struct ChildHeader: View {
    let childName: String
    
    var body: some View {
        HStack {
            ChildBadge(childName: childName)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }
}