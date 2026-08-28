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

    /// "You" only means something once we know who that is on both sides:
    /// the display name for the UI, and the real `profiles.id` for anything
    /// that talks to Supabase. Every participant chip, message and
    /// `is_trip_member` check downstream reads this, so it has to finish
    /// before Home appears — a chat message sent under the wrong id fails
    /// its foreign key silently, which is a much worse debugging experience
    /// than a brief wait here.
    private func bindIdentity() async {
        CurrentUser.adopt(auth.displayName)
        CurrentUser.adoptEmail(auth.email)
        if let id = try? await SupabaseRepository.shared.resolveProfile() {
            CurrentUser.adoptID(id)
            if let face = SupabaseRepository.shared.currentAvatar {
                CurrentUser.adoptAvatar(asset: face.asset, url: face.url)
            }
        }
    }
}

#Preview {
    ContentView()
}
