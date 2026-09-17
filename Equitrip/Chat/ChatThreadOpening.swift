//
//  ChatThreadOpening.swift
//  Equitrip
//

import SwiftUI

/// The whole screen on a thread with no messages yet.
///
/// It used to be a glyph on a tinted disc, a line of instruction and four
/// loose capsules that wrapped into a ragged two-by-two block — visually the
/// emptiest part of the app sat in the middle of the emptiest screen. An
/// empty thread doesn't need a menu; it needs to say which trip you're about
/// to talk in. So it's the trip's own photograph, tilted in a white border
/// like something pinned to a board, under the name in the display face the
/// app keeps for places.
struct ChatThreadOpening: View {
    @Environment(\.tripStore) private var store

    let trip: Trip
    let headcount: String

    /// The photograph settles a beat before the type. The thread fades in
    /// behind a sheet presentation, and a single hard cut of the whole block
    /// read as a loading glitch.
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            photo
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.94)
                .rotationEffect(.degrees(appeared ? -4 : 0))
                .animation(.smooth(duration: 0.55), value: appeared)

            Text(trip.title)
                .font(AppTheme.display(27))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.top, 26)
                .rise(appeared, delay: 0.08)

            Text(caption)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
                .rise(appeared, delay: 0.12)

            Text("No messages yet.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.inkTertiary.opacity(0.7))
                .padding(.top, 18)
                .rise(appeared, delay: 0.18)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .onAppear { appeared = true }
    }

    /// A square rather than the wide cover the rest of the app uses: a
    /// letterboxed strip floating in the middle of an empty screen reads as a
    /// banner that lost its card, and a square reads as a picture.
    private var photo: some View {
        DestinationImage(
            query: trip.destination,
            photo: trip.cover,
            fallbackSymbol: trip.symbol,
            fallbackTint: trip.tint,
            onResolve: { store.setCover($0, for: trip.id) }
        )
        .frame(width: 128, height: 128)
        .clipShape(.rect(cornerRadius: 22, style: .continuous))
        .padding(6)
        .background(.white, in: .rect(cornerRadius: 28, style: .continuous))
        .shadow(color: AppTheme.softShadow(.light), radius: 18, y: 8)
        .accessibilityHidden(true)
    }

    private var caption: String {
        let destination = trip.destination.trimmingCharacters(in: .whitespaces)
        return [destination.isEmpty ? nil : destination, trip.dateRange, headcount]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

private extension View {
    /// One staggered entrance, so the opening assembles top-down.
    func rise(_ appeared: Bool, delay: Double) -> some View {
        opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.smooth(duration: 0.45).delay(delay), value: appeared)
    }
}
