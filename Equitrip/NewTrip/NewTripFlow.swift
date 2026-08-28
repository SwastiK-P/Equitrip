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

    var onCreate: (TripDraft) -> Void
    /// Opened straight into joining, e.g. from a scanned link.
    var startOnJoin: Bool = false

    @State private var stage: Stage = .source
    @State private var draft = TripDraft()

    enum Stage: Int, Hashable {
        case source, importing, participants, basics, review, join

        var title: String {
            switch self {
            case .source: "New trip"
            case .importing: "Reading your document"
            case .participants: "Travellers"
            case .basics: "Trip basics"
            case .review: "Check it over"
            case .join: "Join a trip"
            }
        }

        /// Where the back button goes. `source` is the exit.
        var previous: Stage? {
            switch self {
            case .source: nil
            case .importing, .basics, .join: .source
            case .participants: .source
            case .review: .source
            }
        }
    }

    var body: some View {
        ZStack {
            CanvasBackground()

            Group {
                switch stage {
                case .source:
                    TripSourceStage(
                        onImport: { go(.importing) },
                        onManual: {
                            draft = TripDraft()
                            go(.basics)
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
                            go(extracted.needsParticipants ? .participants : .review)
                        },
                        onManualInstead: {
                            draft = TripDraft()
                            go(.basics)
                        }
                    )

                case .participants:
                    TripParticipantsStage(draft: $draft, onContinue: { go(.review) })

                case .basics:
                    TripBasicsStage(draft: $draft, onContinue: { go(.review) })

                case .join:
                    JoinTripFlow()

                case .review:
                    TripReviewStage(
                        draft: $draft,
                        onCreate: {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            onCreate(draft)
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
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 12) {
                CircleGlyphButton(
                    symbol: stage.previous == nil ? "xmark" : "chevron.left",
                    size: 40
                ) {
                    if let previous = stage.previous {
                        go(previous, backwards: true)
                    } else {
                        dismiss()
                    }
                }
                .accessibilityLabel(stage.previous == nil ? "Close" : "Back")

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
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    private func go(_ next: Stage, backwards: Bool = false) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            stage = next
        }
    }
}

// MARK: - Source

/// The fork: import a document, build it by hand, or join someone else's.
///
/// Rebuilt from three shouting cards into a list. The cards each carried a
/// saturated 46pt tile, a rounded display title, a two-line paragraph and a
/// coloured call-to-action — four competing emphases on a screen whose whole
/// job is one choice, which is what made it read as a landing page rather than
/// a step. Apple's own first-run pickers are lists: one line each, a glyph in
/// the gutter, and the detail underneath in secondary text.
private struct TripSourceStage: View {
    let onImport: () -> Void
    let onManual: () -> Void
    let onJoin: () -> Void

    @State private var appeared = false

    private var availability: IntelligenceAvailability {
        TripExtractor().availability
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headline
                    .padding(.bottom, 26)
                    .staggered(0, appeared)

                VStack(spacing: 0) {
                    SourceRow(
                        symbol: "doc.text",
                        title: "Import a document",
                        detail: "Pull the flights, stays and activities out of a booking PDF.",
                        badge: availability.isReady ? "Apple Intelligence" : nil,
                        action: onImport
                    )

                    Hairline(inset: 60)

                    SourceRow(
                        symbol: "square.and.pencil",
                        title: "Start from scratch",
                        detail: "Set the dates and who's coming, then add bookings as they're made.",
                        action: onManual
                    )

                    Hairline(inset: 60)

                    SourceRow(
                        symbol: "qrcode",
                        title: "Join with a code",
                        detail: "Scan an organiser's invite, or type the code they sent you.",
                        action: onJoin
                    )
                }
                .cardSurface(corner: 20)
                .staggered(1, appeared)

                if !availability.isReady {
                    fallbackNote
                        .padding(.top, 16)
                        .staggered(2, appeared)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .onAppear { appeared = true }
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("New trip")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text("However it starts, you'll check everything before the group sees it.")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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

/// One choice. Monochrome glyph in a fixed gutter, title, supporting line,
/// chevron — the shape of every list row Apple ships, and the reason this
/// screen now reads as a step rather than an advert.
private struct SourceRow: View {
    let symbol: String
    let title: String
    let detail: String
    var badge: String?
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 30, height: 26)

                VStack(alignment: .leading, spacing: 3) {
                    // Title gets the full row width to itself — putting the
                    // badge beside it was what forced "Import a document" to
                    // wrap, which then made the badge sit beside the wrapped
                    // second line instead of the title.
                    Text(title)
                        .font(.system(size: 16.5, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)

                    Text(detail)
                        .font(.system(size: 13.5))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.inkTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(AppTheme.cardStroke.opacity(0.07), in: .capsule)
                            .padding(.top, 2)
                    }
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
    }
}
