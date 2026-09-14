//
//  DestinationImage.swift
//  Equitrip
//

import SwiftUI

/// A photograph of a place, with a designed fallback.
///
/// Three states, in order of preference: a photo we already resolved, a photo
/// fetched now, or a gradient built from the trip's own colour. The fallback
/// matters — with no photo key configured, or offline, every cover in the app
/// still looks deliberate rather than broken.
struct DestinationImage: View {
    let query: String?
    var photo: TripPhoto?
    var fallbackSymbol: String = "suitcase.fill"
    var fallbackTint: Color = AppTheme.accent
    /// Lets a parent persist the resolved photo so it stops being re-fetched.
    var onResolve: ((TripPhoto) -> Void)?

    @State private var resolved: TripPhoto?
    @State private var didLoad = false

    private var active: TripPhoto? { photo ?? resolved }

    /// Everything is drawn as an *overlay* on a `Color.clear` that takes
    /// whatever size it is offered, rather than as a `ZStack` the photograph
    /// is a member of.
    ///
    /// A fill-scaled resizable image reports the size it had to grow to in
    /// order to cover the proposal, which for a tall, narrow frame — a 360pt
    /// cover in a 348pt-wide rail — is far wider than the frame asked for. In
    /// a stack that size becomes the stack's size and then the card's, and the
    /// column it lives in ends up laid out around a number nobody chose;
    /// `.clipped()` doesn't help, because clipping is about drawing and this
    /// is about layout. An overlay can't report anything back to its parent,
    /// so the frame the caller asked for is the frame that happens.
    var body: some View {
        Color.clear
            .overlay { fallback }
            .overlay {
                if let active {
                    AsyncImage(url: active.url, transaction: Transaction(animation: .easeOut(duration: 0.35))) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .transition(.opacity)
                        default:
                            // Keep the fallback showing rather than flashing a
                            // grey box between request and first byte.
                            Color.clear
                        }
                    }
                }
            }
            .clipped()
            .task(id: query) { await load() }
    }

    private var fallback: some View {
        LinearGradient(
            colors: [fallbackTint.opacity(0.95), fallbackTint.opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: fallbackSymbol)
                .font(.system(size: 90, weight: .semibold))
                .foregroundStyle(.white.opacity(0.16))
                .rotationEffect(.degrees(-12))
                .offset(x: 18, y: 14)
        }
    }

    private func load() async {
        guard photo == nil, !didLoad else { return }
        guard let query, !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        didLoad = true
        if let hit = PhotoService.shared.cached(query) {
            resolved = hit
            onResolve?(hit)
            return
        }

        guard let fetched = await PhotoService.shared.photo(for: query) else { return }
        resolved = fetched
        onResolve?(fetched)
    }
}
