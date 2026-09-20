//
//  TripRecapView.swift
//  Equitrip
//

import SwiftUI

/// The trip, wrapped: a finished trip told back as a handful of cards instead
/// of a ledger to audit.
///
/// The ledger answers "is this right?", which is the question while a trip is
/// running. Once it's over the questions change — what did that cost us, where
/// did it all go, who carried it, are we done — and they're asked twice: once
/// about the group and once about yourself. So one screen, one switch between
/// the two lenses, and the same cards underneath so the answers line up.
///
/// Full-screen rather than a sheet because it opens on the photograph: the
/// place comes first and the arithmetic second, which is the order anybody
/// remembers a trip in.
struct TripRecapView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tripStore) private var store
    @Environment(\.pane) private var pane

    let trip: Trip

    @State private var lens: TripRecap.Lens = .group
    @State private var appeared = false
    @Namespace private var lensSwitch

    private var recap: TripRecap { TripRecap(trip: trip) }

    var body: some View {
        ZStack(alignment: .top) {
            CanvasBackground()

            if pane.isWide {
                spread
            } else {
                column
            }
        }
        .onAppear {
            // A beat after the cover lands, so the numbers roll up on a screen
            // that's already still rather than mid-transition.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(180))
                appeared = true
            }
        }
    }

    // MARK: - Layouts

    /// Phone and narrow iPad: the photograph across the top, the lens switch
    /// on its bottom edge, the cards underneath.
    private var column: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    hero

                    lensPicker
                        .padding(.top, -24)
                        .zIndex(1)

                    // Phone keeps its tighter 16pt card margin; on iPad the
                    // cards share the pane's gutter with the hero text and
                    // the top bar, so all three line up on one edge.
                    cards
                        .padding(.horizontal, pane.isRegular ? pane.gutter : 16)
                        .padding(.top, pane.isRegular ? 26 : 18)
                        .pageWidth()

                    Color.clear.frame(height: pane.isRegular ? 60 : 44)
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)

            topButtons
                .padding(.horizontal, pane.gutter)
                .pageWidth()
                .padding(.top, 4)
        }
    }

    /// Full-screen iPad: the photograph as a panel down the left, the cards
    /// scrolling beside it — the trip-details layout, read back as a recap.
    ///
    /// A banner across 1200pt is a letterbox: to stay a sensible height it has
    /// to crop the picture to a strip, and it still pushes the numbers half a
    /// screen down. Standing it up as a panel gives the place its full height
    /// and leaves the numbers on screen from the first frame, in one column at
    /// a width they read well at.
    private var spread: some View {
        HStack(spacing: 0) {
            photoPanel
                .frame(width: panelWidth)

            ScrollView {
                cards
                    .padding(.horizontal, pane.gutter)
                    .padding(.top, 6)
                    .padding(.bottom, 44)
                    .frame(maxWidth: 740)
                    .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .safeAreaBar(edge: .top) {
                lensPicker
                    .padding(.top, 16)
                    .padding(.bottom, 10)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
        }
    }

    /// Around two-fifths of the window: enough for the photograph to be the
    /// first thing you see, while the column beside it keeps room for four
    /// highlight tiles across.
    private var panelWidth: CGFloat {
        min(540, max(400, pane.width * 0.4))
    }

    // MARK: - Photograph

    private var cover: some View {
        DestinationImage(
            query: trip.destination,
            photo: trip.cover,
            fallbackSymbol: trip.symbol,
            fallbackTint: trip.tint,
            onResolve: { store.setCover($0, for: trip.id) }
        )
    }

    private var hero: some View {
        // Grows with the pane, but never past about half its height: a
        // landscape 11" iPad is only 834pt tall, and a photo that fills it
        // pushes every number below the fold.
        let height = min(pane.scaled(420, regular: 480), max(420, pane.height * 0.56))

        return GeometryReader { proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let stretch = max(0, minY)

            cover
                .frame(width: proxy.size.width, height: height + stretch)
                .scaleEffect(appeared ? 1 : 1.08, anchor: .bottom)
                .animation(.easeOut(duration: 1.4), value: appeared)
                .clipped()
                .offset(y: -stretch)
        }
        .frame(height: height)
        .overlay { ProgressiveBlur(edge: .bottom, begins: 0.38, scrim: 0.46) }
        .overlay(alignment: .bottomLeading) {
            heroCaption
                .padding(.horizontal, pane.isRegular ? pane.gutter : 22)
                .padding(.bottom, pane.isRegular ? 54 : 46)
                .pageWidth()
        }
    }

    /// The photograph full height, with the trip's name at its foot and the
    /// close and share buttons on it — the same pieces as the banner, stood up.
    ///
    /// Flush to the window's edges like the trip-details sheet, rather than a
    /// card inset from them: it's the screen's other half, not one more card
    /// beside the cards. The photo ignores the safe area; the buttons and the
    /// caption stay inside it, clear of the status bar and home indicator.
    private var photoPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            topButtons
                .padding(.top, 4)

            Spacer(minLength: 0)

            heroCaption
                .padding(.bottom, 24)
        }
        .padding(.horizontal, pane.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            // Filling a clear rectangle rather than framing the image: a photo
            // asked to fill a fixed tall frame keeps its own aspect and
            // overflows it, which the clip then crops from the middle.
            Color.clear
                .overlay {
                    cover
                        .scaleEffect(appeared ? 1 : 1.06)
                        .animation(.easeOut(duration: 1.4), value: appeared)
                }
                .clipped()
                .overlay { ProgressiveBlur(edge: .bottom, begins: 0.5, scrim: 0.5) }
                .ignoresSafeArea()
        }
    }

    private var heroCaption: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(trip.title)
                .tripTitle(trip.titleStyle, size: pane.scaled(40, wide: 52, regular: 48))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .staggered(0, appeared, base: 0.08)

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Label(trip.destination.isEmpty ? "Somewhere good" : trip.destination, systemImage: "mappin.and.ellipse")
                        .lineLimit(1)
                    Text("\(trip.dateRange) · \(trip.dayCount.pluralised("day")) · \(recap.members.count.pluralised("traveller"))")
                }
                .font(.system(size: pane.isRegular ? 15 : 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
                .labelStyle(TightLabelStyle())

                Spacer(minLength: 8)

                AvatarStack(travellers: recap.members, size: pane.isRegular ? 36 : 30, max: pane.isRegular ? 6 : 4, departedIDs: trip.departedIDs)
            }
            .padding(.top, 8)
            .staggered(1, appeared, base: 0.08)
        }
        .shadow(color: .black.opacity(0.28), radius: 10, y: 2)
    }

    // MARK: - Chrome

    private var topButtons: some View {
        GlassEffectContainer(spacing: 12) {
            HStack {
                CircleGlyphButton(symbol: "xmark", size: 40) { dismiss() }
                    .accessibilityLabel("Close recap")

                Spacer()

                ShareLink(item: recap.shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: 40, height: 40)
                        .contentShape(.circle)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share recap")
            }
        }
    }

    /// Straddles the photograph's bottom edge, so the switch reads as the hinge
    /// between the place and the numbers about it.
    private var lensPicker: some View {
        HStack(spacing: 4) {
            ForEach(TripRecap.Lens.allCases, id: \.self) { option in
                let on = lens == option

                Button {
                    guard !on else { return }
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { lens = option }
                } label: {
                    HStack(spacing: 7) {
                        if option == .you {
                            TravellerAvatar(traveller: .you, size: 20)
                        } else {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        Text(option.label)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(on ? AppTheme.ctaLabel : AppTheme.inkSecondary)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .background {
                        if on {
                            Capsule()
                                .fill(AppTheme.cta)
                                .matchedGeometryEffect(id: "lens", in: lensSwitch)
                        }
                    }
                    .contentShape(.capsule)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .glassEffect(.regular.tint(.white.opacity(0.6)), in: .capsule)
        .shadow(color: AppTheme.softShadow(.light), radius: 16, y: 8)
    }

    // MARK: - Cards

    /// One column in every layout, every gap the same `cardSpacing` — the
    /// highlight tiles included, so the grid doesn't read as a tighter block.
    private var cards: some View {
        VStack(spacing: cardSpacing) {
            headline
            breakdown
            days
            people
            highlights
            squaring
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: lens)
    }

    private var cardSpacing: CGFloat { pane.spacing(14) }

    private var headline: some View {
        RecapHeadlineCard(recap: recap, lens: lens, appeared: appeared)
            .staggered(0, appeared, base: 0.07)
    }

    @ViewBuilder
    private var breakdown: some View {
        let slices = recap.slices(lens)
        if !slices.isEmpty {
            RecapBreakdownCard(recap: recap, slices: slices, lens: lens, appeared: appeared)
                .staggered(1, appeared, base: 0.07)
        }
    }

    @ViewBuilder
    private var days: some View {
        if recap.total(lens) > 0 {
            // A regular pane fits a fortnight across before the bars get thin
            // enough to need scrolling; a phone manages about ten.
            RecapDaysCard(recap: recap, days: recap.days(lens), lens: lens, appeared: appeared, fits: pane.isRegular ? 16 : 10)
                .staggered(2, appeared, base: 0.07)
        }
    }

    @ViewBuilder
    private var people: some View {
        switch lens {
        case .group:
            if recap.contributors.contains(where: { $0.paid > 0 }) {
                RecapPayersCard(recap: recap, appeared: appeared)
                    .staggered(3, appeared, base: 0.07)
                    .transition(.opacity)
            }
        case .you:
            if !recap.yourPayments.isEmpty {
                RecapYourPaymentsCard(recap: recap)
                    .staggered(3, appeared, base: 0.07)
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var highlights: some View {
        let tiles = recap.highlights(lens)
        if !tiles.isEmpty {
            // An iPad column is wide enough for the tiles as one row.
            let across = pane.isRegular ? max(2, tiles.count) : 2
            RecapHighlightsGrid(highlights: tiles, columns: across, spacing: cardSpacing)
                .staggered(4, appeared, base: 0.07)
        }
    }

    private var squaring: some View {
        RecapSquaringCard(recap: recap, lens: lens)
            .staggered(5, appeared, base: 0.07)
    }
}

/// Icon and text a little closer than the system spacing — on the hero, where
/// the default gap reads as two separate labels.
private struct TightLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.icon.font(.system(size: 11, weight: .bold))
            configuration.title
        }
    }
}

// MARK: - Entry

/// What a finished trip shows above its plan: the door into the recap.
///
/// A plain card with the trip's own photograph as its icon, so it reads as
/// part of this trip's screen rather than as a promotion laid over it.
struct TripRecapEntryCard: View {
    let trip: Trip
    var action: () -> Void

    private var caption: String {
        var parts = [trip.projectedLabel, trip.items.count.pluralised("booking")]
        switch TripRecap(trip: trip).squaring(.group) {
        case .square: parts.append("all square")
        case .open(let transfers, let pending) where !transfers.isEmpty || !pending.isEmpty:
            parts.append("\(max(transfers.count, pending.count)) to settle")
        default: break
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 12) {
                DestinationImage(
                    query: trip.destination,
                    photo: trip.cover,
                    fallbackSymbol: trip.symbol,
                    fallbackTint: trip.tint
                )
                .frame(width: 44, height: 44)
                .clipShape(.rect(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Trip recap")
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(caption)
                        .font(.system(size: 12.5))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .padding(12)
            .cardSurface(corner: 20)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Open trip recap")
    }
}
