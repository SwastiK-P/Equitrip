//
//  NewTripFlow.swift
//  Equitrip
//

import SwiftUI

/// Creating a trip, both ways in.
///
/// The two routes converge deliberately: importing a PDF and filling the form
/// by hand both end at the same review screen, because in either case the
/// person needs to check what's about to become the group's shared truth
/// before it goes in. The import route is a head start, not a shortcut past
/// that check.
struct NewTripFlow: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pane) private var pane

    var onCreate: (TripDraft) -> Void
    /// Opened straight into joining, e.g. from a scanned link.
    var startOnJoin: Bool = false

    @State private var stage: Stage = .source
    @State private var draft = TripDraft()
    /// The screens actually visited, so Back retraces them.
    ///
    /// It used to be a static `previous` on the stage, and every stage's
    /// answer was `.source` — which meant Back from the review screen walked
    /// past the form that had just been filled in and landed on the fork, and
    /// choosing "From scratch" again reset the draft. One mistyped date cost
    /// the whole trip.
    @State private var trail: [Stage] = []
    @State private var route: Route = .manual

    /// Which way into the flow this is. The two routes are different lengths,
    /// and a progress track that says "3" on a two-screen run is worse than no
    /// track at all.
    private enum Route {
        /// Where, when, who, check.
        case manual
        /// Read it, who, check — the document has already answered the first
        /// two questions, which is the whole point of importing one.
        case imported

        var steps: Int { self == .manual ? 4 : 3 }
    }

    enum Stage: Int, Hashable {
        case source, importing, participants, place, dates, review, join

        var title: String {
            switch self {
            case .source: "New trip"
            case .importing: "Reading your document"
            case .participants: "Who's coming?"
            case .place: "Where to?"
            case .dates: "When?"
            case .review: "Check it over"
            case .join: "Join a trip"
            }
        }
    }

    /// How far along this route the current screen is, or nil for the screens
    /// that aren't part of it. The fork and the join flow are separate
    /// errands, not steps toward a trip.
    private var step: Int? {
        switch stage {
        case .source, .join: nil
        case .place, .importing: 1
        case .dates: 2
        case .participants: route == .manual ? 3 : 2
        case .review: route.steps
        }
    }

    var body: some View {
        ZStack {
            CanvasBackground()

            Group {
                switch stage {
                case .source:
                    TripSourceStage(
                        onImport: {
                            route = .imported
                            go(.importing)
                        },
                        onManual: {
                            // Only a draft the reader built gets thrown away.
                            // One the person typed is still theirs — backing
                            // out to the fork and changing their mind about
                            // the route shouldn't cost them the form.
                            if draft.wasImported { draft = TripDraft() }
                            route = .manual
                            go(.place)
                        },
                        onJoin: { go(.join) }
                    )

                case .importing:
                    TripImportStage(
                        onExtracted: { extracted in
                            draft = extracted
                            // A document that counted heads without naming them
                            // leaves a question only the person can answer, and
                            // it has to be answered before the costs mean
                            // anything. A document that named everybody, or
                            // never mentioned a number, skips this.
                            //
                            // Replaces rather than pushes: the import screen is
                            // finished with, and Back onto it would only hand
                            // the person a file picker they've already used.
                            replace(with: extracted.needsParticipants ? .participants : .review)
                        },
                        onManualInstead: {
                            draft = TripDraft()
                            route = .manual
                            replace(with: .place)
                        }
                    )

                case .place:
                    TripPlaceStage(draft: $draft, onContinue: { go(.dates) })

                case .dates:
                    TripDatesStage(draft: $draft, onContinue: { go(.participants) })

                case .participants:
                    TripParticipantsStage(draft: $draft, onContinue: { go(.review) })

                case .join:
                    JoinTripFlow()

                case .review:
                    TripReviewStage(
                        draft: $draft,
                        onCreate: {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            onCreate(draft)
                            GlassToastCenter.shared.show(.init(
                                symbol: "checkmark.circle.fill",
                                tint: AppTheme.positive,
                                title: "Trip created",
                                subtitle: "\"\(draft.title)\" is ready — start adding bookings.",
                                duration: .seconds(3.5)
                            ))
                            dismiss()
                        }
                    )
                }
            }
            .transition(
                .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            )
            // One measure for all six stages rather than six separate caps.
            //
            // A wizard is the one shape on iPad that shouldn't grow into the
            // window: it asks one question at a time, and a question spread
            // across 1200pt is harder to answer than the same question in a
            // column — the eye has to travel from a label on one side of the
            // room to the field it belongs to on the other. Sheets of this
            // kind are a single centred column in every Apple app that has
            // one, and for the same reason.
            // Except the opening fork on a wide iPad, which isn't a question
            // with a field to answer but a choice between three doors — and
            // that reads better laid out across the room than stacked in a
            // column with half the window empty beneath it.
            .readableWidth(unless: usesWideSource)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) {
            if stage != .join { header }
        }
        .onAppear {
            if startOnJoin { stage = .join }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 9) {
            GlassEffectContainer(spacing: 16) {
                HStack(spacing: 12) {
                    CircleGlyphButton(
                        symbol: trail.isEmpty ? "xmark" : "chevron.left",
                        size: 40
                    ) { back() }
                    .accessibilityLabel(trail.isEmpty ? "Close" : "Back")

                    Spacer(minLength: 0)

                    Text(stage.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .contentTransition(.opacity)

                    Spacer(minLength: 0)

                    // Balances the back button so the title stays optically centred.
                    Color.clear.frame(width: 40, height: 40)
                }
            }

            if let step {
                StepTrack(step: step, of: route.steps)
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, usesWideSource ? pane.gutter : 20)
        .frame(maxWidth: usesWideSource ? pane.pageWidth : pane.readableWidth)
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    private var usesWideSource: Bool { stage == .source && pane.isWide }

    private func go(_ next: Stage) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            trail.append(stage)
            stage = next
        }
    }

    /// Moves on without leaving a way back to where we were — for a screen
    /// that has done its job and can't usefully be returned to.
    private func replace(with next: Stage) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            stage = next
        }
    }

    private func back() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            if let previous = trail.popLast() {
                stage = previous
            } else {
                dismiss()
            }
        }
    }
}

// MARK: - Progress

/// Three cells that fill as the flow advances.
///
/// Deliberately not a percentage bar: the steps aren't equal lengths and
/// nobody is estimating time here. What it answers is "how much more of this
/// is there", which a form with no visible end is bad at telling you.
private struct StepTrack: View {
    let step: Int
    let of: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...of, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? AppTheme.accent : AppTheme.cardStroke.opacity(0.12))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.85), value: step)
        .accessibilityElement()
        .accessibilityLabel("Step \(step) of \(of)")
    }
}

// MARK: - Source

/// The fork: import a document, build it by hand, or join someone else's.
///
/// It was a list of three rows — a glyph in a gutter, a title, two lines of
/// explanation each. Correct, legible, and completely inert: the first thing
/// anybody sees when they decide to plan a trip was a settings screen. This
/// gives the choice some shape instead. The import route, which is the one
/// worth taking when there's a booking email sitting in your inbox, gets a
/// full-width card with room for an illustration; the other two share a row
/// underneath, which also says something true about their relative weight.
private struct TripSourceStage: View {
    let onImport: () -> Void
    let onManual: () -> Void
    let onJoin: () -> Void

    @Environment(\.pane) private var pane
    @State private var appeared = false

    private var availability: IntelligenceAvailability {
        TripExtractor().availability
    }

    var body: some View {
        Group {
            if pane.isWide {
                wideBody
            } else {
                stackedBody
            }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    // MARK: iPad

    /// The fork, laid out for a landscape iPad: the question on the left at a
    /// size that can carry the room, the three answers on the right, and the
    /// whole thing sitting in the middle of the window rather than hanging off
    /// the top of it.
    ///
    /// The import card keeps its lead — it's the full width of its column and
    /// twice the height of the other two — so the hierarchy the phone draws
    /// with a stack is drawn here with size instead.
    private var wideBody: some View {
        ScrollView {
            HStack(alignment: .center, spacing: 56) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Where are we")
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)

                        Text("going?")
                            .font(AppTheme.display(52))
                            .foregroundStyle(AppTheme.accent)
                    }

                    Text("Bring a booking and let the itinerary build itself, set one up by hand, or hop onto a trip a friend has already planned.")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if !availability.isReady {
                        fallbackNote
                            .padding(.top, 4)
                    }
                }
                .frame(width: 340, alignment: .leading)
                .staggered(0, appeared)

                VStack(spacing: 16) {
                    importCard(illustration: 210, scale: 1.35)
                        .staggered(1, appeared)

                    HStack(spacing: 16) {
                        manualCard
                            .staggered(2, appeared)
                        joinCard
                            .staggered(3, appeared)
                    }
                }
                .frame(maxWidth: 620)
            }
            .padding(.horizontal, pane.gutter)
            .padding(.vertical, 24)
            .frame(maxWidth: pane.pageWidth)
            .frame(maxWidth: .infinity)
            .containerRelativeFrame(.vertical, alignment: .center) { length, _ in length }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: Phone

    private var stackedBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headline
                    .staggered(0, appeared)

                importCard()
                    .staggered(1, appeared)

                HStack(spacing: 12) {
                    manualCard
                        .staggered(2, appeared)
                    joinCard
                        .staggered(3, appeared)
                }

                if !availability.isReady {
                    fallbackNote
                        .staggered(4, appeared)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
    }

    private var manualCard: some View {
        smallCard(
            symbol: "square.and.pencil",
            title: "From scratch",
            detail: "Where, when, who.",
            tint: Palette.greenDeep,
            action: onManual
        )
    }

    private var joinCard: some View {
        smallCard(
            symbol: "qrcode.viewfinder",
            title: "Join a trip",
            detail: "Scan or type a code.",
            tint: Palette.violetDeep,
            action: onJoin
        )
    }

    // MARK: Headline

    private var headline: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Where are we")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text("going?")
                .font(AppTheme.display(32))
                .foregroundStyle(AppTheme.accent)
        }
        .padding(.bottom, 2)
    }

    // MARK: Import

    /// The lead card. The illustration is the point of it: three booking chips
    /// fanned out of a document, which says what the import actually does in
    /// less space than the sentence underneath it needs.
    private func importCard(illustration: CGFloat = 132, scale: CGFloat = 1) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onImport()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                DocumentFan()
                    .scaleEffect(scale)
                    .frame(height: illustration)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Import a document")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)
                    }

                    Text("Drop in a booking PDF — flights, stays and activities come out the other side.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                LinearGradient(
                    colors: [AppTheme.accent.opacity(0.16), AppTheme.accent.opacity(0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .background(AppTheme.card)
            }
            .clipShape(.rect(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(AppTheme.accent.opacity(0.16))
            }
            .shadow(color: AppTheme.softShadow(.light), radius: 14, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: Secondary

    private func smallCard(
        symbol: String,
        title: String,
        detail: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 46, height: 46)
                    .background(tint.opacity(0.13), in: .circle)

                Spacer(minLength: 14)

                Text(title)
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 148, alignment: .topLeading)
            .padding(14)
            .background(AppTheme.card, in: .rect(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(AppTheme.cardStroke.opacity(0.05))
            }
            .shadow(color: AppTheme.softShadow(.light), radius: 10, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var fallbackNote: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "info.circle")
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.top, 1)

            Text(availability.detail)
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Illustration

/// A page with three bookings coming off it.
///
/// Drawn rather than shipped as an asset so it picks up the app's own palette
/// and stays crisp at any size. The chips drift in on a stagger the first time
/// the screen appears and then hold still — the motion is there to explain the
/// picture once, not to keep performing.
private struct DocumentFan: View {
    @State private var appeared = false

    private struct Chip {
        let symbol: String
        let tint: Color
        let offset: CGSize
        let angle: Double
        let width: CGFloat
    }

    private static let chips: [Chip] = [
        .init(symbol: "airplane", tint: Palette.blue, offset: CGSize(width: 54, height: -30), angle: -8, width: 96),
        .init(symbol: "bed.double.fill", tint: Palette.violet, offset: CGSize(width: 74, height: 6), angle: 4, width: 108),
        .init(symbol: "figure.hiking", tint: Palette.green, offset: CGSize(width: 58, height: 42), angle: -3, width: 92)
    ]

    var body: some View {
        ZStack {
            page
                .offset(x: -62)
                .rotationEffect(.degrees(-5))

            ForEach(Array(Self.chips.enumerated()), id: \.offset) { index, chip in
                bookingChip(chip)
                    .offset(
                        x: appeared ? chip.offset.width : chip.offset.width - 40,
                        y: chip.offset.height
                    )
                    .rotationEffect(.degrees(appeared ? chip.angle : chip.angle - 6))
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.72)
                        .delay(0.12 + Double(index) * 0.09),
                        value: appeared
                    )
            }
        }
        .onAppear { appeared = true }
        .accessibilityHidden(true)
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(0..<5, id: \.self) { row in
                Capsule()
                    .fill(AppTheme.inkTertiary.opacity(row == 0 ? 0.35 : 0.16))
                    .frame(width: row == 0 ? 42 : [64, 54, 60, 38][row - 1], height: row == 0 ? 6 : 4)
            }
        }
        .frame(width: 84, height: 106, alignment: .topLeading)
        .padding(14)
        .background(AppTheme.card, in: .rect(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(AppTheme.cardStroke.opacity(0.08))
        }
        .shadow(color: AppTheme.softShadow(.light), radius: 8, y: 4)
    }

    private func bookingChip(_ chip: Chip) -> some View {
        HStack(spacing: 7) {
            Image(systemName: chip.symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(chip.tint, in: .circle)

            VStack(alignment: .leading, spacing: 3) {
                Capsule().fill(AppTheme.inkTertiary.opacity(0.32)).frame(width: 40, height: 4)
                Capsule().fill(AppTheme.inkTertiary.opacity(0.18)).frame(width: 26, height: 4)
            }

            Spacer(minLength: 0)
        }
        .padding(6)
        .frame(width: chip.width)
        .background(AppTheme.card, in: .rect(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(AppTheme.cardStroke.opacity(0.06))
        }
        .shadow(color: AppTheme.softShadow(.light), radius: 7, y: 3)
    }
}
