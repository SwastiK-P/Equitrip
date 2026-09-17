//
//  ContentView.swift
//  Equitrip
//
//  Created by Swastik Patil on 27/08/26.
//

import SwiftUI

struct ContentView: View {
    private enum Route: Equatable {
        case launching
        case onboarding
        case auth(AuthMode)
        case home
    }

    @State private var route: Route = .launching
    @State private var auth = AuthService.shared

    var body: some View {
        ZStack {
            switch route {
            case .launching:
                // Held until the persisted session check finishes, so a
                // signed-in user never sees onboarding flash past.
                ZStack {
                    CanvasBackground()
                    ProgressView().tint(AppTheme.inkTertiary)
                }

            case .onboarding:
                OnboardingView(
                    onSignIn: { go(.auth(.signIn)) },
                    onCreateAccount: { go(.auth(.createAccount)) }
                )

            case .auth(let mode):
                AuthView(
                    mode: mode,
                    onBack: { go(.onboarding) },
                    // Swapping modes re-creates the view so its fields and
                    // stagger replay for the new form.
                    onSwitchMode: { go(.auth($0)) },
                    onAuthenticated: {
                        Task {
                            await bindIdentity()
                            go(.home)
                        }
                    }
                )
                .id(mode)

            case .home:
                RootTabView(
                    userName: auth.displayName,
                    onSignOut: {
                        Task {
                            await auth.signOut()
                            go(.onboarding)
                        }
                    }
                )
            }
        }
        .task {
            await auth.restore()
            if auth.isSignedIn { await bindIdentity() }
            go(auth.isSignedIn ? .home : .onboarding)
        }
    }

    /// Screens swap instantly — no cross-screen transition.
    private func go(_ destination: Route) {
        route = destination
    }

    /// Has to finish before Home appears — see `AuthService.bindIdentity()`.
    private func bindIdentity() async {
        await auth.bindIdentity()
    }
}

#Preview {
    ContentView()
}
