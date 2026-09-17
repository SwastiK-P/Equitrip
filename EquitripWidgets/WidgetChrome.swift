//
//  WidgetChrome.swift
//  EquitripWidgets
//

import SwiftUI
import WidgetKit

// MARK: - Canvas

/// The ground every widget stands on, whichever slot it is in.
///
/// `containerBackground` is not optional furniture — a widget that never
/// declares one is refused outright and drawn as "Please adopt the
/// containerBackground API", which is exactly what the lock-screen families
/// did while only the home-screen ones were being given the peach gradient.
/// So the modifier goes on once, at the root of the body, and picks what to
/// fill with by family:
///
/// - home screen gets the peach gradient, the same one the app opens on;
/// - the circular slot gets `AccessoryWidgetBackground`, the system's own
///   dimmed disc, because a lock-screen ring without it floats;
/// - the rectangular and inline slots get nothing, which is correct rather
///   than lazy — those are drawn as vibrant text directly on the wallpaper.
struct WidgetCanvas: ViewModifier {
    @Environment(\.widgetFamily) private var family

    func body(content: Content) -> some View {
        content.containerBackground(for: .widget) { fill }
    }

    @ViewBuilder
    private var fill: some View {
        switch family {
        case .accessoryCircular:
            AccessoryWidgetBackground()
        case .accessoryRectangular, .accessoryInline:
            Color.clear
        default:
            LinearGradient(
                colors: [Brand.canvasTop, Brand.canvasBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

extension View {
    func widgetCanvas() -> some View { modifier(WidgetCanvas()) }
}

// `MoneyTone` and `EquitripSnapshot.Event.tint` live in
// EquitripShared/SnapshotStyle.swift, shared with the watch app.

// MARK: - Split bar

/// Owed-to-you against owed-by-you as one bar, segmented exactly as Home's is.
///
/// The ratio is the thing being read, not the two figures — and the segments
/// are what keep it reading as a measure rather than as a progress bar that
/// has stalled somewhere odd.
struct SplitBar: View {
    let fraction: Double
    var cells: Int = 16
    var height: CGFloat = 9

    private var owed: Int {
        min(cells, max(0, Int((Double(cells) * fraction).rounded())))
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<cells, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(index < owed ? Brand.accent : Brand.danger.opacity(0.32))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Figure

/// A dotted label over a figure — Home's `heroFigure`, at widget scale.
struct DottedFigure: View {
    let label: String
    let value: String
    let dot: Color
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 1 : 3) {
            HStack(spacing: 4) {
                Circle()
                    .fill(dot)
                    .frame(width: compact ? 4.5 : 6, height: compact ? 4.5 : 6)
                Text(label)
                    .font(.system(size: compact ? 10 : 12, weight: .medium))
                    .foregroundStyle(Brand.inkSecondary)
            }
            Text(value)
                .font(.system(size: compact ? 14 : 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Brand.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Scope line

/// The quiet header every widget opens with: what these numbers are about.
struct ScopeLine: View {
    let title: String
    var symbol: String = "square.stack.3d.up"
    var trailing: String?

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 9.5, weight: .bold))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)

            if let trailing {
                Spacer(minLength: 6)
                Text(trailing)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Brand.inkTertiary)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(Brand.accent)
    }
}

// MARK: - Symbol badge

/// The tinted disc a booking wears everywhere in the app.
struct WidgetSymbolBadge: View {
    let symbol: String
    let tint: Color
    var size: CGFloat = 28

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.14), in: .rect(cornerRadius: size * 0.32, style: .continuous))
    }
}

// MARK: - Initial avatar

/// A person as a widget can draw them: an initial on a tinted disc.
///
/// The snapshot carries names, not photos — a widget has no session to fetch
/// a profile picture with. The tint is picked from the name's scalars rather
/// than `hashValue`, which Swift reseeds every launch and would repaint the
/// same person a different colour on each timeline reload.
struct InitialAvatar: View {
    let name: String
    var size: CGFloat = 28
    /// A canvas-coloured ring, for avatars that overlap in a stack.
    var ringed = false

    private static let palette: [Color] = [Brand.blue, Brand.violet, Brand.teal, Brand.amber, Brand.green, Brand.indigo]

    private var tint: Color {
        let seed = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return Self.palette[abs(seed) % Self.palette.count]
    }

    private var initial: String {
        name.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "?"
    }

    var body: some View {
        Text(initial)
            .font(.system(size: size * 0.44, weight: .bold, design: .rounded))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            // Opaque card under the tint, so an avatar stacked over another
            // hides it instead of letting the one behind show through.
            .background {
                ZStack {
                    Circle().fill(Brand.card)
                    Circle().fill(tint.opacity(0.16))
                }
            }
            .overlay {
                if ringed { Circle().strokeBorder(Brand.canvasTop, lineWidth: 2) }
            }
    }
}

// MARK: - Day track

/// One cell per day of a trip, lit up to today — Home's `ProgressTrack` at
/// widget scale, so "Day 3 of 6" and the bar beside it count the same thing.
///
/// Capped at fourteen cells: a month-long trip at widget width is thirty
/// slivers too thin to read, and past that point the cells stop being days
/// and become a proportion anyway.
struct DayTrack: View {
    let progress: Double
    let days: Int
    var tint: Color = Brand.accent
    var height: CGFloat = 5

    private var count: Int { min(14, max(1, days)) }

    private var filled: Int {
        let clamped = min(1, max(0, progress))
        guard clamped > 0 else { return 0 }
        return min(count, max(1, Int((Double(count) * clamped).rounded(.up))))
    }

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index < filled ? tint : Brand.cardStroke.opacity(0.10))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Hairline

struct WidgetHairline: View {
    var body: some View {
        Rectangle()
            .fill(Brand.cardStroke.opacity(0.08))
            .frame(height: 1)
    }
}

// MARK: - Clock gutter

/// `4:30` over `PM`, right-aligned in a fixed gutter, so a column of rows
/// lines up on the colon the way the trip timeline does.
struct ClockGutter: View {
    let value: String?
    let meridiem: String?
    var width: CGFloat = 38

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if let value {
                Text(value)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.ink)
                Text(meridiem ?? "")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(Brand.inkTertiary)
            } else {
                Text("All\nday")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Brand.inkTertiary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(width: width, alignment: .trailing)
    }
}

// MARK: - Empty state

/// What every widget says when there is nothing to say.
///
/// One view rather than four hand-written variants, because the sentence is
/// the same in all of them and the thing that must never happen is a widget
/// drawing a confident `₹0` for an account that simply hasn't loaded yet.
struct WidgetEmptyState: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Brand.accent)

            Spacer(minLength: 0)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Brand.ink)
            Text(detail)
                .font(.system(size: 11.5))
                .foregroundStyle(Brand.inkSecondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
