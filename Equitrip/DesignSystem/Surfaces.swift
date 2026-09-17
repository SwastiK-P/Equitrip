//
//  Surfaces.swift
//  Equitrip
//

import SwiftUI

// MARK: - Canvas

/// The single-hue peach gradient every screen in the app sits on.
struct CanvasBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AppTheme.canvasTop, AppTheme.canvasBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Card surface

/// The white card the whole app is built from: fill, hairline edge and a
/// warm-tinted lift. Applied as a modifier so every card matches by default
/// and one-off cards can't drift.
struct CardSurface: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    var corner: CGFloat = 20
    var shadow: CGFloat = 10
    /// Marks a card as something nobody planned ahead of time — added after
    /// the trip was already under way, rather than during the original
    /// itinerary pass. A dashed, accent-tinted edge instead of the usual
    /// hairline, so it reads as "logged on the fly" at a glance rather than
    /// needing a badge to say so.
    var dashed: Bool = false
    /// Overrides the top corners only — for a card that sits directly under
    /// a fixed header it's currently attached to (see `AuditTrailSheet`),
    /// where the header carries the rounding instead. Nil keeps all four
    /// corners at `corner`, which is what every other card wants.
    var topCorner: CGFloat?

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: topCorner ?? corner,
                bottomLeading: corner,
                bottomTrailing: corner,
                topTrailing: topCorner ?? corner
            ),
            style: .continuous
        )
    }

    func body(content: Content) -> some View {
        content
            .background(AppTheme.card, in: shape)
            .overlay {
                shape.strokeBorder(
                    dashed ? AppTheme.accent.opacity(0.4) : AppTheme.cardStroke.opacity(scheme == .dark ? 0.09 : 0.045),
                    style: dashed ? StrokeStyle(lineWidth: 1.8, dash: [5, 4]) : StrokeStyle(lineWidth: 1)
                )
            }
            .shadow(color: AppTheme.softShadow(scheme), radius: shadow, y: shadow * 0.35)
    }
}

extension View {
    func cardSurface(corner: CGFloat = 20, shadow: CGFloat = 10, dashed: Bool = false, topCorner: CGFloat? = nil) -> some View {
        modifier(CardSurface(corner: corner, shadow: shadow, dashed: dashed, topCorner: topCorner))
    }
}

/// Row separator that matches the card edge instead of the system grey.
struct Hairline: View {
    @Environment(\.colorScheme) private var scheme

    var inset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(AppTheme.cardStroke.opacity(scheme == .dark ? 0.10 : 0.07))
            .frame(height: 1)
            .padding(.leading, inset)
    }
}

// MARK: - Section header

/// Title above a group of cards, with an optional trailing action.
struct SectionHeader: View {
    let title: String
    var caption: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            if let caption {
                Text(caption)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 6)

            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 3) {
                        Text(actionTitle)
                            .font(.system(size: 13.5, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10.5, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }
}

// MARK: - Connection

/// Says the server couldn't be reached, and offers the one thing that helps.
///
/// Deliberately a banner rather than a full-screen error: whatever was already
/// loaded stays readable underneath it. Losing the connection halfway through
/// a trip shouldn't blank the trip.
struct ConnectionBanner: View {
    let message: String
    var retry: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.danger)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text("Couldn't reach the server")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text(message)
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            Button("Try again", action: retry)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .buttonStyle(PressableButtonStyle())
        }
        .padding(14)
        .background(AppTheme.danger.opacity(0.07), in: .rect(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppTheme.danger.opacity(0.18))
        }
    }
}

/// The "we're still asking" state, shaped like the content it will become so
/// the screen doesn't jump when the answer arrives.
struct LoadingState: View {
    var message: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(AppTheme.inkTertiary)

            Text(message)
                .font(.system(size: 13.5))
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Chips

/// Small capsule label. Tint carries the meaning; the fill is a wash of it.
struct TagChip: View {
    let title: String
    var tint: Color = AppTheme.accent
    var symbol: String?

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4.5)
        .background(tint.opacity(0.13), in: .capsule)
    }
}

// MARK: - Shared icon tile

/// Solid tile carrying a white glyph. Defaults to the same fill as the primary
/// button so icon rows read as one family rather than a colour swatch set.
struct IconTile: View {
    @Environment(\.colorScheme) private var scheme

    let symbol: String
    var tint: Color?
    var size: CGFloat = 38
    var corner: CGFloat = 11

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(tint ?? AppTheme.cta)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.44, weight: .semibold))
                    .foregroundStyle(tint == nil ? AppTheme.ctaLabel : .white)
            }
            .frame(width: size, height: size)
            .shadow(color: AppTheme.softShadow(scheme), radius: 8, y: 4)
    }
}

// MARK: - Symbol badge

/// Soft tinted disc carrying a matching glyph. The quiet counterpart to
/// `IconTile`: used in list rows, where a grid of saturated tiles would shout.
struct SymbolBadge: View {
    let symbol: String
    var tint: Color
    var size: CGFloat = 36

    var body: some View {
        Circle()
            .fill(tint.opacity(0.14))
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: size, height: size)
    }
}
