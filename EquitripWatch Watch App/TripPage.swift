//
//  TripPage.swift
//  EquitripWatch Watch App
//

import SwiftUI

/// The trip in view, as its photograph — Home's current-trip card given the
/// whole screen.
///
/// On the phone that card is the first thing anybody looks at, and it works
/// because the picture *is* the trip: you know which one it is before you
/// read a word. Shrunk into a row inside the Balance page it stopped doing
/// that, so here the cover is the page itself — container background, edge to
/// edge, the name set in the trip's own typeface — with the two questions the
/// card answers (how far in, what it costs you) on the glass panel at the foot.
///
/// Deliberately not a `ScrollView`: it is one card, it fits, and a page that
/// scrolls a few points under the crown reads as broken rather than as more
/// content. Everything sizes down instead.
struct TripPage: View {
    @Environment(WatchStore.self) private var store

    /// How far the panel is held off the sides. The screen's own curve is
    /// already accounted for by watchOS's content margin; this is on top of
    /// it, and matches the inset Maps gives its result card.
    private let inset: CGFloat = 5
    /// Under the phase caption. Small: the caption's own line already holds
    /// the panel well clear of the foot, and more on top of it left the card
    /// riding high with dead photograph under it.
    private let bottomInset: CGFloat = 1

    var body: some View {
        Group {
            if let trip = store.trip {
                hero(trip)
            } else {
                WatchNotice(
                    symbol: "suitcase",
                    title: "No trip in view",
                    detail: "Create or join a trip on your iPhone and it shows up here."
                )
            }
        }
        // The phase is the caption under the card, not the navigation title:
        // it belongs to the trip on screen rather than to the page, and the
        // bar is better left to the clock — Maps does the same with its
        // "10 Results".
        .navigationTitle("")
    }

    /// "Happening now" for the trip under way, and what the phase actually is
    /// otherwise — the wrist should never imply a trip has started.
    private var phaseLabel: String {
        switch store.trip?.phase {
        case .live: "Happening now"
        case .past: "Finished"
        default: "Up next"
        }
    }

    // MARK: Hero

    private func hero(_ trip: EquitripSnapshot.TripSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 0) {
                Text(trip.title)
                    .tripTitle(TripTitleStyle(stored: trip.titleStyle), size: 26)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)

                Text(subtitle(trip))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .shadow(color: .black.opacity(0.45), radius: 6, y: 1)
            // The type sits over the panel's own left edge, as on the phone
            // card, where both are inset from the photograph together.
            .padding(.horizontal, 4)

            Panel(trip: trip)

            phaseCaption
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(.horizontal, inset)
        // The foot is the caption's, and the caption's own line is what holds
        // the panel off the bottom of the screen — a floating card on watchOS
        // is held further off the foot than off the sides, and matching all
        // three made it read as stuck to the edge. The safe area is ignored
        // first because a page's bottom inset is a scroll allowance, not a
        // margin, and leaving it in would stack on top of this.
        .padding(.bottom, bottomInset)
        .ignoresSafeArea(edges: .bottom)
        // `.tabView`, not `.navigation` — see `watchPageTint`: on the shared
        // navigation container the photograph lingered behind the next page
        // for a second after every turn of the crown.
        .containerBackground(for: .tabView) {
            CoverImage(url: trip.coverURL, symbol: trip.symbol, symbolAlignment: .top)
                .overlay {
                    // Deepest where the type sits. The cover is somebody's own
                    // photograph — a bright beach or a night street — and white
                    // has to hold on both.
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.3), location: 0),
                            .init(color: .black.opacity(0.08), location: 0.3),
                            .init(color: .black.opacity(0.55), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
    }

    /// Where the trip is in its life, centred under the card. Words only —
    /// the phone's phase chip carries a dot because it sits in the corner of
    /// a photograph with nothing else to read it against; here the line says
    /// the whole thing on its own, and the dot was just a speck.
    private var phaseCaption: some View {
        Text(phaseLabel)
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.7))
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.top, 1)
    }

    /// Home's own subtitle — "16–24 Sep · 1 booking · ₹2,000" — dropping
    /// whichever pieces an older phone build didn't send.
    private func subtitle(_ trip: EquitripSnapshot.TripSummary) -> String {
        [trip.dateRange, trip.bookingLabel, trip.projectedLabel]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

// MARK: - Panel

/// How far in on the left, where you stand on the right — the phone card's
/// glass panel, in the same glass: a tinted `.regular` over the photograph,
/// so it takes its colour from whatever cover is behind it.
private struct Panel: View {
    let trip: EquitripSnapshot.TripSummary

    /// Before the trip starts nobody has paid for anything, so `netLabel`
    /// would read "Settled" — what it'll cost you is the true figure then.
    private var showsBalance: Bool { trip.showsBalance ?? (trip.phase != .upcoming) }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            progress

            Rectangle()
                .fill(.white.opacity(0.22))
                .frame(width: 1, height: 30)

            standing
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(
            .regular.tint(.black.opacity(0.22)),
            in: .rect(cornerRadius: 20, style: .continuous)
        )
        .environment(\.colorScheme, .dark)
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(trip.progressLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            DayTrack(progress: trip.progress, days: trip.dayCount ?? 1, tint: .white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var standing: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(showsBalance ? trip.netLabel : (trip.yourShareLabel ?? "—"))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: 3) {
                // Direction survives on dark glass as a dot; the brand indigo
                // as a text colour doesn't — the same call the phone makes.
                if showsBalance {
                    Circle()
                        .fill(MoneyTone.of(trip.net))
                        .frame(width: 4, height: 4)
                }
                Text(showsBalance ? trip.netCaption : "your share")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            showsBalance
                ? "\(trip.netCaption), \(trip.netLabel.unsignedMoney)"
                : "Your share, \(trip.yourShareLabel ?? "unknown")"
        )
    }
}

#Preview {
    NavigationStack { TripPage() }
        .environment(WatchStore(preview: .placeholder))
}
