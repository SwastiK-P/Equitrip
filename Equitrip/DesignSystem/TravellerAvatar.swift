//
//  TravellerAvatar.swift
//  Equitrip
//

import SwiftUI

// MARK: - Travellers

/// The avatar artwork is a filled circle in its own right, cropped so the
/// art's edge *is* the frame's edge — clipping to a circle lands exactly on
/// it, with nothing behind to tint and no rim of background left over.
///
/// A traveller who has uploaded a photograph gets that instead of the avatar,
/// not behind it — the two are exclusive, not layered. The avatar is only
/// ever what's drawn while the photo is still loading; once it succeeds the
/// avatar is gone entirely, and a broken URL falls back to it rather than
/// showing both at once.
struct TravellerAvatar: View {
    @Environment(\.colorScheme) private var scheme
    let traveller: Traveller
    var size: CGFloat
    /// Drawn greyed and slightly faded — how somebody who has left a trip
    /// appears everywhere their face still does.
    ///
    /// Desaturation rather than a badge, because the avatar row is already on
    /// screen in a dozen places and a badge on each of them would need a
    /// legend. Grey reads as "not current" without one, and the name and dates
    /// are one tap away for anybody who wants them.
    var isDimmed: Bool = false

    var body: some View {
        Group {
            if let url = traveller.avatarURL {
                AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
                    if case let .success(image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        artwork
                    }
                }
            } else {
                artwork
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .saturation(isDimmed ? 0 : 1)
        .opacity(isDimmed ? 0.55 : 1)
        .overlay {
            Circle().strokeBorder(AppTheme.card, lineWidth: size > 30 ? 1.5 : 1)
        }
        .shadow(color: AppTheme.softShadow(scheme), radius: 5, y: 2)
    }

    /// Filled, not fitted, and unpadded: the art already ends where the circle
    /// does, so insetting it would reintroduce the empty ring this artwork was
    /// cropped to remove.
    private var artwork: some View {
        Image(Traveller.artwork(for: traveller.asset))
            .resizable()
            .scaledToFill()
    }
}

/// Overlapping avatar cluster with an overflow count, so a twelve-person trip
/// reads at the same width as a three-person one.
struct AvatarStack: View {
    let travellers: [Traveller]
    var size: CGFloat = 32
    var max: Int = 4
    /// Anyone who has left the trip. Greyed in place rather than dropped, so
    /// a booking they were on still shows who was actually on it — the group
    /// that ate that dinner doesn't change because one of them flew home.
    var departedIDs: Set<UUID> = []

    private var shown: ArraySlice<Traveller> { travellers.prefix(max) }
    private var overflow: Int { Swift.max(0, travellers.count - max) }

    var body: some View {
        HStack(spacing: -size * 0.3) {
            ForEach(Array(shown.enumerated()), id: \.offset) { slot, traveller in
                TravellerAvatar(
                    traveller: traveller,
                    size: size,
                    isDimmed: departedIDs.contains(traveller.id)
                )
                .zIndex(Double(shown.count - slot))
            }

            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .frame(width: size, height: size)
                    .background(AppTheme.canvasBottom, in: .circle)
                    .overlay { Circle().strokeBorder(AppTheme.card, lineWidth: size > 30 ? 1.5 : 1) }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(travellers.count.pluralised("traveller"))
    }
}
