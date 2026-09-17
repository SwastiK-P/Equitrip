//
//  WatchChrome.swift
//  EquitripWatch Watch App
//

import SwiftUI

/// The watch's pieces of the app's design language.
///
/// Each one is the phone's own component at wrist scale rather than a watch
/// invention: the split bar is Home's upright cells, the trip track is one
/// capsule per day, the card is the same warm surface. Somebody who knows the
/// app should recognise every screen without learning a second vocabulary.
///
/// Sized in text styles, not points. The watch HIG puts the default at 16pt
/// and the floor at 12, and a person who has turned text up on a 41mm watch
/// has done it for a reason — so every label here is a Dynamic Type style,
/// and the furniture around them scales with `@ScaledMetric` so a bigger
/// setting grows the badges and gutters too instead of crowding them.

// MARK: - Card

/// The warm surface every group of content sits on — `Brand.card`, which on
/// the watch is always its dark value.
///
/// A generous fixed radius, close to the screen's own curve. (A
/// `ContainerRelativeShape` would be the principled way to echo it, but with
/// no container shape defined above these cards it resolves to a plain
/// rectangle and the corners square off.)
struct WatchCard: ViewModifier {
    var padding: CGFloat = 10
    var fill: Color = Brand.card

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: .rect(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    func watchCard(padding: CGFloat = 10, fill: Color = Brand.card) -> some View {
        modifier(WatchCard(padding: padding, fill: fill))
    }

    /// The tint the HIG asks for behind a screen: "use background content
    /// such as color to convey useful supporting information". One colour per
    /// page, so turning the crown between them is visible at a glance.
    func watchPageTint(_ color: Color) -> some View {
        containerBackground(color.opacity(0.28).gradient, for: .navigation)
    }
}

// MARK: - Split cells

/// Owed-to-you against owed-by-you — Home's `splitBar`, cell for cell in
/// shape: upright, softly rounded rather than capsules (a capsule this narrow
/// rounds away to a lozenge and stops reading as a cell), full accent against
/// a dimmed danger. Fewer of them, because the screen is.
struct SplitCells: View {
    let fraction: Double
    var cells: Int = 16

    @ScaledMetric(relativeTo: .caption2) private var height: CGFloat = 12

    private var owed: Int {
        min(cells, max(0, Int((Double(cells) * fraction).rounded())))
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<cells, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    // Stronger than the phone's 0.32: that wash sits on white
                    // and reads pink; on black it reads brown.
                    .fill(index < owed ? Brand.accent : Brand.danger.opacity(0.65))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - Day track

/// Home's `ProgressTrack`: one capsule per day of the trip, so the bar and
/// "Day 3 of 6" above it are visibly counting the same thing.
///
/// Capped: past a fortnight the cells get too thin to be cells at this
/// width, so a long trip's days share them instead.
struct DayTrack: View {
    let progress: Double
    let days: Int

    @ScaledMetric(relativeTo: .caption2) private var height: CGFloat = 5

    private var count: Int { min(14, max(1, days)) }

    /// Rounded up, as on the phone — a trip that has started shows at least
    /// one lit cell rather than an empty bar that reads as broken.
    private var filled: Int {
        let clamped = min(1, max(0, progress))
        guard clamped > 0 else { return 0 }
        return min(count, max(1, Int((Double(count) * clamped).rounded(.up))))
    }

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index < filled ? Brand.accent : Color.white.opacity(0.14))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - Figure

/// A dotted label over a figure — Home's `heroFigure`.
struct DottedFigure: View {
    let label: String
    let value: String
    let dot: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Circle().fill(dot).frame(width: 5, height: 5)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(Brand.inkSecondary)
            }
            Text(value)
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(Brand.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Eyebrow

/// The small spaced caps that name a block — "NEXT", "HAPPENING NOW".
struct Eyebrow: View {
    let text: String
    var tint: Color = Brand.accent

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(0.8)
            .foregroundStyle(tint)
    }
}

// MARK: - Symbol badge

/// The tinted disc a booking wears everywhere in the app.
struct SymbolBadge: View {
    let symbol: String
    let tint: Color
    var style: Font.TextStyle = .footnote

    @ScaledMetric private var scale: CGFloat = 1

    private var size: CGFloat { (style == .caption2 ? 22 : 30) * scale }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(style, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.2), in: .circle)
            .accessibilityHidden(true)
    }
}

// MARK: - Clock

/// `6:30` over `AM`, like the phone's itinerary rows — the time is what a
/// column of bookings is read down by, so it gets its own gutter.
struct ClockStack: View {
    let value: String?
    let meridiem: String?

    @ScaledMetric(relativeTo: .caption) private var width: CGFloat = 32

    var body: some View {
        VStack(spacing: -1) {
            if let value {
                Text(value)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(Brand.inkSecondary)
                if let meridiem {
                    Text(meridiem)
                        .font(.caption2)
                        .foregroundStyle(Brand.inkTertiary)
                }
            } else {
                Text("All day")
                    .font(.caption2)
                    .foregroundStyle(Brand.inkTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(width: width)
    }
}

// MARK: - Initial

/// A person as a lettered disc. The watch has no avatars to draw — the
/// snapshot carries names, not artwork — and a letter is what the phone falls
/// back to as well.
struct InitialDisc: View {
    let name: String
    var style: Font.TextStyle = .footnote

    @ScaledMetric private var scale: CGFloat = 1

    private var size: CGFloat { (style == .title3 ? 40 : 30) * scale }

    var body: some View {
        Text(name.first.map(String.init)?.uppercased() ?? "?")
            .font(.system(style, design: .rounded, weight: .bold))
            .foregroundStyle(Brand.accent)
            .frame(width: size, height: size)
            .background(Brand.accent.opacity(0.2), in: .circle)
            .accessibilityHidden(true)
    }
}

// MARK: - Message

/// A whole-screen sentence, for the states with nothing to draw.
struct WatchNotice: View {
    let symbol: String
    let title: String
    let detail: String

    @ScaledMetric private var disc: CGFloat = 48

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.accent)
                    .frame(width: disc, height: disc)
                    .background(Brand.accent.opacity(0.16), in: .circle)
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Brand.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
        }
    }
}

// MARK: - Staleness

/// "Updated 2h ago", and whether the phone is even there. Only drawn once
/// it's true: a watch quietly showing an old balance is worse than one
/// admitting it.
struct StaleFooter: View {
    @Environment(WatchStore.self) private var store

    var body: some View {
        if store.isStale {
            HStack(spacing: 5) {
                Image(systemName: store.isPhoneReachable ? "clock" : "iphone.slash")
                Group {
                    if let synced = store.lastSynced {
                        Text("Updated \(synced, format: .relative(presentation: .named))")
                    } else {
                        Text("Not synced yet")
                    }
                }
            }
            .font(.caption2)
            .foregroundStyle(Brand.inkTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Type

extension Font {
    /// The app's serif display face, as a Dynamic Type style rather than a
    /// fixed size — a trip's name is the one place the app leaves the system
    /// sans, and it should still grow with everything else.
    static func display(_ style: Font.TextStyle) -> Font {
        .system(style, design: .serif, weight: .bold)
    }
}

// MARK: - Money for VoiceOver

extension String {
    /// `+₹3,180` without its sign, so VoiceOver reads the caption and then
    /// the figure — "you get back, ₹3,180" — rather than "plus".
    var unsignedMoney: String {
        trimmingCharacters(in: CharacterSet(charactersIn: "+−-"))
    }
}

// MARK: - Dates

extension Date {
    /// `Sat 12 Sep` — the exact pattern of the phone's `TripDay.subtitle`, so
    /// a day reads the same on both. A localized template puts a comma in
    /// ("Sat, 12 Sep") and reorders it in some regions.
    var tripDayLabel: String { Self.tripDayFormatter.string(from: self) }

    private static let tripDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        return formatter
    }()
}
