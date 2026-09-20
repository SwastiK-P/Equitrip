//
//  OnboardingView.swift
//  Equitrip
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.pane) private var pane

    @State private var appeared = false

    var onSignIn: () -> Void = {}
    var onCreateAccount: () -> Void = {}

    /// The swipeable pages, in order. Showcase pages are trials: dropping one
    /// is removing its case here and deleting its file.
    enum Page: Hashable, CaseIterable {
        case welcome, bookings
    }

    /// Remembered for the life of the process, because `ContentView` rebuilds
    /// this view on the way back from sign-in — without it, backing out of
    /// the form from page two dropped you on page one.
    private static var lastPage: Page = .welcome
    @State private var page: Page = OnboardingView.lastPage

    var body: some View {
        ZStack {
            CanvasBackground()

            if Page.allCases.count == 1 {
                welcome
            } else {
                TabView(selection: $page) {
                    ForEach(Page.allCases, id: \.self) { page in
                        content(for: page)
                            .task { await enter() }
                            .tag(page)
                    }
                }
                // Our own dots, so each page can place them in its layout
                // (the bookings page puts them above its headline).
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: page) { _, now in OnboardingView.lastPage = now }
            }
        }
    }

    @ViewBuilder
    private func content(for page: Page) -> some View {
        switch page {
        case .welcome:
            welcome
        case .bookings:
            GeometryReader { geo in
                VStack(spacing: 0) {
                    BookingsShowcase(visible: self.page == .bookings, compact: geo.size.height < 780) {
                        dots
                    }
                    actions(for: .bookings)
                        .padding(.horizontal, 20)
                        .padding(.top, geo.size.height < 780 ? 16 : 26)
                }
                .padding(.bottom, 6)
                .frame(maxWidth: pane.isWide ? 520 : pane.readableWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var dots: some View {
        OnboardingPageDots(count: Page.allCases.count, current: Page.allCases.firstIndex(of: page) ?? 0)
    }

    /// The entrance is triggered from the page itself (see `enter()`). Flipped
    /// from the outer `ZStack`, it landed before the paging `TabView` had built
    /// its first page, and the page came up with everything still at zero
    /// opacity — a blank screen until a swipe.
    private var welcome: some View {
        Group {
            if pane.isWide {
                spread
            } else {
                column
            }
        }
        .task { await enter() }
    }

    /// Runs from whichever page is on screen first — page two too, when
    /// coming back from sign-in — a tick after it's in the hierarchy.
    private func enter() async {
        guard !appeared else { return }
        await Task.yield()
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { appeared = true }
    }

    /// The phone layout, and iPad in portrait: one column, hero at the top.
    ///
    /// Fixed — no scrolling. Spacers absorb the slack, and the compact branch
    /// keeps it whole on shorter devices.
    private var column: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 780

            VStack(spacing: 0) {
                Spacer(minLength: compact ? 12 : 24)

                OnboardingHero(appeared: appeared)
                    .frame(height: compact ? 168 : 190)

                // Fixed, deliberately tight — the remaining slack goes to
                // the flexible spacers, which pushes the deck down the page.
                headline
                    .padding(.top, compact ? 10 : 14)

                Spacer(minLength: compact ? 14 : 24)

                features

                Spacer(minLength: compact ? 14 : 24)

                actions(for: .welcome)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
            .frame(maxWidth: pane.readableWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// iPad in landscape: the promise on one side, the proof on the other.
    ///
    /// The single column is a phone shape stood up — 190pt of illustration,
    /// then a headline, then three cards, then two buttons, and on a landscape
    /// iPad it either floats in the middle of a very wide screen or stretches
    /// until the feature rows are a glyph and a sentence separated by a foot
    /// of white. Landscape is a *wide* window, not a short tall one, so the
    /// page turns ninety degrees with it: the illustration and the claim it
    /// makes stay together on the left, the three things the app actually does
    /// and the way in sit on the right, and nothing has to shrink.
    private var spread: some View {
        HStack(alignment: .center, spacing: 56) {
            VStack(spacing: 0) {
                OnboardingHero(appeared: appeared)
                    // The deck is drawn at a fixed 324pt — it's an
                    // illustration made of real cards, and rebuilding it
                    // fluid would mean re-tuning the depth offsets that make
                    // it read as a deck. Scaled instead, which is what you'd
                    // do with any other piece of artwork given more wall.
                    .scaleEffect(1.2)
                    .frame(height: 250)

                headline
                    .padding(.top, 26)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 26) {
                features
                actions(for: .welcome)
            }
            .frame(maxWidth: 420)
        }
        .padding(.horizontal, 56)
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Headline

    private var headline: some View {
        VStack(spacing: 10) {
            Text("Split the trip,\nnot the friendship.")
                .font(.system(size: pane.isRegular ? 38 : 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text("Every booking, expense and balance in one shared plan.")
                .font(.system(size: pane.isRegular ? 17 : 15))
                .foregroundStyle(AppTheme.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 14)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.28), value: appeared)
    }

    // MARK: - Feature cards

    private var features: some View {
        VStack(spacing: 12) {
            ForEach(Array(OnboardingFeature.all.enumerated()), id: \.element.id) { index, feature in
                FeatureCard(feature: feature)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 22)
                    .animation(
                        .spring(response: 0.62, dampingFraction: 0.82)
                        .delay(0.38 + Double(index) * 0.08),
                        value: appeared
                    )
            }
        }
    }

    // MARK: - Actions

    /// Every page but the last leads on with Continue; the last one is the
    /// way in. Keyed to the page being drawn rather than the selection,
    /// because the pager renders its neighbours while you swipe — reading
    /// `page` here put the wrong buttons on the page sliding in.
    private func actions(for current: Page) -> some View {
        let pages = Page.allCases
        let index = pages.firstIndex(of: current) ?? 0
        let next = index + 1 < pages.count ? pages[index + 1] : nil

        return VStack(spacing: 6) {
            if current == .welcome, pages.count > 1 {
                dots.padding(.bottom, 10)
            }

            if let next {
                PrimaryButton(title: "Continue", systemImage: nil, capsule: true) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) { page = next }
                }
            } else {
                PrimaryButton(title: "Sign in", systemImage: nil, capsule: true, action: onSignIn)

                TextButton(title: "New to Equitrip?", emphasis: "Create account", action: onCreateAccount)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 26)
        .animation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.6), value: appeared)
    }
}

// MARK: - Page dots

/// The pager's position, drawn by hand so a page can put it where its
/// composition wants it rather than pinned to the bottom edge.
struct OnboardingPageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? AppTheme.ink : AppTheme.inkTertiary.opacity(0.35))
                    .frame(width: index == current ? 20 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: current)
        .accessibilityElement()
        .accessibilityLabel("Page \(current + 1) of \(count)")
    }
}

// MARK: - Feature card

private struct FeatureCard: View {
    @Environment(\.colorScheme) private var scheme
    let feature: OnboardingFeature

    var body: some View {
        HStack(spacing: 14) {
            IconTile(symbol: feature.symbol)

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(feature.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppTheme.cardStroke.opacity(scheme == .dark ? 0.08 : 0.04))
        }
        .shadow(color: AppTheme.softShadow(scheme), radius: 14, y: 6)
    }
}

// MARK: - Model

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let subtitle: String

    static let all: [OnboardingFeature] = [
        .init(
            symbol: "point.bottomleft.forward.to.point.topright.scurvepath.fill",
            title: "One itinerary, everyone in sync.",
            subtitle: "Flights, stays and activities in one plan."
        ),
        .init(
            symbol: "arrow.triangle.2.circlepath",
            title: "Shares recalculate themselves.",
            subtitle: "Balances update when plans change."
        ),
        .init(
            symbol: "checkmark",
            title: "Settle with proof, not promises.",
            subtitle: "You mark a payment, they confirm it."
        )
    ]
}

#Preview("Light") {
    OnboardingView()
}

#Preview("Dark") {
    OnboardingView()
        .preferredColorScheme(.dark)
}
