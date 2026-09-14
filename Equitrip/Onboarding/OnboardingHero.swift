//
//  OnboardingHero.swift
//  Equitrip
//

import Combine
import SwiftUI

/// A swipeable deck of real trip cards. Auto-advances on a timer, and the
/// front card can be dragged to shuffle it to the back by hand.
///
/// Deliberately *not* a scatter of floating bubbles — the composition is
/// grid-aligned and every card is a fragment of the actual product.
struct OnboardingHero: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var appeared: Bool

    @State private var index = 0
    @State private var dragY: CGFloat = 0
    @State private var lastChange = Date()

    private let trips = TripCard.all
    private let haptics = UIImpactFeedbackGenerator(style: .soft)
    private let tick = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    /// Cards sit further back the deeper they are; only three are ever drawn.
    private static let depthScale: [CGFloat] = [1, 0.94, 0.88]
    private static let depthOffset: [CGFloat] = [0, -21, -40]

    var body: some View {
        deck
            .onAppear { haptics.prepare() }
            .onReceive(tick) { _ in autoAdvanceIfIdle() }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Trip cards")
            .accessibilityValue(trips[index].title)
            .accessibilityHint("Swipe up to see the next trip")
            .accessibilityAdjustableAction { direction in
                advance(by: direction == .increment ? 1 : -1)
            }
    }

    // MARK: - Deck

    private var deck: some View {
        ZStack {
            ForEach(Array(trips.enumerated()), id: \.element.id) { position, trip in
                let depth = depth(of: position)

                if depth < Self.depthScale.count {
                    TripCardView(trip: trip)
                        // Cards behind are veiled so their content doesn't
                        // peek above the front card as stray coloured slivers.
                        .overlay {
                            if depth > 0 {
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(AppTheme.card)
                                    .opacity(depth == 1 ? 0.72 : 0.9)
                            }
                        }
                        // Dragging up shrinks the front card as it travels, so
                        // it reads as being pushed back into the deck.
                        .scaleEffect(Self.depthScale[depth] - (depth == 0 ? dragProgress * 0.1 : 0))
                        .offset(y: Self.depthOffset[depth] + (depth == 0 ? dragY : 0))
                        .opacity(depth == 2 ? 0.75 : 1)
                        .zIndex(Double(Self.depthScale.count - depth))
                }
            }
        }
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.82), value: appeared)
        .gesture(swipe)
    }

    /// 0…1 as the front card is dragged up toward the commit threshold.
    private var dragProgress: CGFloat {
        min(1, max(0, -dragY / Self.swipeThreshold))
    }

    private static let swipeThreshold: CGFloat = 52

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                // Downward drag is damped — the deck only really goes one way.
                let raw = value.translation.height
                dragY = raw < 0 ? raw : raw * 0.3
            }
            .onEnded { value in
                if value.translation.height < -Self.swipeThreshold {
                    advance(by: 1)
                } else if value.translation.height > Self.swipeThreshold * 1.6 {
                    advance(by: -1)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { dragY = 0 }
                }
            }
    }

    // MARK: - Paging

    /// How far behind the front card this position currently sits.
    private func depth(of position: Int) -> Int {
        (position - index + trips.count) % trips.count
    }

    private func advance(by delta: Int) {
        haptics.impactOccurred()
        lastChange = Date()

        // The outgoing card recedes into the back of the deck rather than
        // flying off — it reads as one continuous shuffle.
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            index = (index + delta + trips.count) % trips.count
            dragY = 0
        }
    }

    private func autoAdvanceIfIdle() {
        guard !reduceMotion, appeared, dragY == 0 else { return }
        guard Date().timeIntervalSince(lastChange) >= 3.5 else { return }

        lastChange = Date()
        withAnimation(.spring(response: 0.55, dampingFraction: 0.84)) {
            index = (index + 1) % trips.count
        }
    }
}

// MARK: - Card

private struct TripCardView: View {
    @Environment(\.colorScheme) private var scheme
    let trip: TripCard

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                IconTile(symbol: trip.symbol, tint: trip.tint, size: 40, corner: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(trip.detail)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .lineLimit(1)

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(trip.total)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text("total")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .lineLimit(1)
                .fixedSize()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)

            Divider().overlay(AppTheme.cardStroke.opacity(0.08))

            HStack(spacing: 10) {
                HStack(spacing: -11) {
                    ForEach(Array(trip.travellers.enumerated()), id: \.offset) { slot, traveller in
                        TravellerAvatar(traveller: traveller, size: 36)
                            .zIndex(Double(trip.travellers.count - slot))
                    }
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(trip.net)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(trip.netColor)
                    Text(trip.netCaption)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .lineLimit(1)
                .fixedSize()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(width: 324)
        .background(AppTheme.card, in: .rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(AppTheme.cardStroke.opacity(scheme == .dark ? 0.10 : 0.05))
        }
        .shadow(color: AppTheme.softShadow(scheme), radius: 26, x: 0, y: 14)
    }
}

// MARK: - Model

struct TripCard: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let symbol: String
    let tint: Color
    let total: String
    let travellers: [Traveller]
    let net: String
    let netCaption: String
    let netColor: Color

    static let all: [TripCard] = [
        .init(
            title: "Goa escape",
            detail: "12–15 Dec · 5 travellers",
            symbol: "beach.umbrella.fill",
            tint: Palette.amber,
            total: "₹48,200",
            travellers: Traveller.all,
            net: "+₹4,400",
            netCaption: "you get back",
            netColor: AppTheme.accent
        ),
        .init(
            title: "Manali ski trip",
            detail: "8–12 Jan · 4 travellers",
            symbol: "snowflake",
            tint: Palette.blue,
            total: "₹62,750",
            travellers: [.ed, .krishna, .mattew, .kim],
            net: "−₹2,150",
            netCaption: "you owe",
            netColor: AppTheme.danger
        ),
        .init(
            title: "Kerala backwaters",
            detail: "3–6 Mar · 3 travellers",
            symbol: "ferry.fill",
            tint: Palette.violet,
            total: "₹31,400",
            travellers: [.priya, .krishna, .kim],
            net: "Settled",
            netCaption: "all square",
            netColor: AppTheme.inkSecondary
        )
    ]
}
