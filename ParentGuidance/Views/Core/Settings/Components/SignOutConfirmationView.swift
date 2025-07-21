//
//  SignOutConfirmationView.swift
//  ParentGuidance
//
//  Created by alex kerss on 21/07/2025.
//

import SwiftUI

struct SignOutConfirmationView: View {
    @ObservedObject var viewState: SettingsViewState
    let handleSignOut: () -> Void
    
    var body: some View {
        Group {
            if viewState.showingSignOutConfirmation {
                ZStack {
                    // Semi-transparent background
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            viewState.showingSignOutConfirmation = false
                        }
                    
                    // Confirmation dialog
                    ConfirmationDialog(
                        title: String(localized: "settings.account.signOut.title"),
                        message: String(localized: "settings.account.signOut.message"),
                        destructiveButtonTitle: String(localized: "settings.account.signOut"),
                        onDestruct: {
                            handleSignOut()
                        },
                        onCancel: {
                            viewState.showingSignOutConfirmation = false
                        }
                    )
                }
                .zIndex(3000)
            }
        }
    }
}
