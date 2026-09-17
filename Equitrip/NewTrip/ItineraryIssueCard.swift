//
//  ItineraryIssueCard.swift
//  Equitrip
//

import SwiftUI

/// What the consistency check found, on the screen where it can still be
/// acted on cheaply.
///
/// Built to read as a sibling of `TripReviewStage.importNote` — same surface,
/// same 14pt padding, same glyph-then-two-lines header — because they are the
/// same kind of remark: this is what was read, and this is what looks wrong
/// with it. Two differently shaped notices stacked on one screen would read as
/// two unrelated systems talking.
///
/// It reports and nothing else. Every row opens the booking it names in the
/// editor the review screen already presents; nothing here writes to a
/// booking, because a warning that quietly moves someone else's flight is a
/// worse problem than the one it fixed.
struct ItineraryIssueCard: View {
    let state: ItineraryCheckState
    let issues: [ItineraryIssue]
    /// How many bookings were actually checked. Carried only so the all-clear
    /// can't claim more than it did — one booking has nothing to clash with,
    /// and saying the plan was read and looks fine would be flattery.
    let bookingCount: Int
    var onOpen: (UUID) -> Void

    /// Long lists start folded. The card is a remark on a screen about
    /// bookings, and six warnings unfurled push the bookings off the bottom of
    /// it — which inverts what the screen is for.
    @State private var expanded = false

    private var worst: ItineraryIssue.Severity? {
        issues.map(\.severity).max()
    }

    private var visible: [ItineraryIssue] {
        expanded || issues.count <= 4 ? issues : Array(issues.prefix(3))
    }

    private var hidden: Int { issues.count - visible.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if !visible.isEmpty {
                ForEach(Array(visible.enumerated()), id: \.element.id) { index, issue in
                    Hairline(inset: index == 0 ? 0 : 14)
                    row(issue)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))

                if hidden > 0 {
                    Hairline(inset: 14)
                    moreButton
                }
            }
        }
        .panelSurface(corner: 18)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: issues)
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: expanded)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            headerGlyph

            VStack(alignment: .leading, spacing: 2) {
                Text(headerTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text(headerSubtitle)
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
    }

    @ViewBuilder
    private var headerGlyph: some View {
        let glyph = Image(systemName: headerSymbol)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(headerTint)
            .padding(.top, 1)

        if case .checking = state {
            glyph.symbolEffect(.breathe, options: .repeating)
        } else {
            glyph
        }
    }

    private var headerSymbol: String {
        if case .checking = state { return "apple.intelligence" }
        if issues.isEmpty { return "checkmark.seal.fill" }
        return worst == .likelyWrong ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill"
    }

    private var headerTint: Color {
        if case .checking = state { return AppTheme.accent }
        if issues.isEmpty { return AppTheme.positive }
        return worst?.tint ?? Palette.amber
    }

    private var headerTitle: String {
        if case .checking = state {
            return issues.isEmpty ? "Checking your plan…" : "Still checking…"
        }
        if issues.isEmpty { return "Nothing looks off" }
        return "\(issues.count.pluralised("thing")) worth checking"
    }

    /// Says which reader did the work, on the same terms `importNote` does —
    /// the pattern-matching pass finds real clashes but it doesn't understand
    /// anything, and claiming otherwise oversells it.
    private var headerSubtitle: String {
        switch state {
        case .checking:
            return issues.isEmpty
                ? "Looking for bookings that clash."
                : "\(issues.count) so far, and still reading."

        case .done(let usedFallback):
            if issues.isEmpty {
                guard bookingCount > 1 else {
                    return "One booking so far — nothing for it to clash with."
                }
                return usedFallback
                    ? "Apple Intelligence wasn't available, so this was a quick pattern check of your times."
                    : "Apple Intelligence read your plan and the bookings line up."
            }
            return usedFallback
                ? "Apple Intelligence wasn't available, so this is a rough pass — worth a careful look."
                : "Tap any of these to open the booking."
        }
    }

    // MARK: - One issue

    private func row(_ issue: ItineraryIssue) -> some View {
        Button {
            guard let id = issue.itemIDs.first else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onOpen(id)
        } label: {
            HStack(alignment: .top, spacing: 11) {
                SymbolBadge(symbol: issue.symbol, tint: issue.severity.tint, size: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(issue.headline)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .multilineTextAlignment(.leading)

                    Text(issue.problem)
                        .font(.system(size: 12.5))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    // The fix is the reason the row exists, so it gets its own
                    // line and its own mark rather than being a third sentence
                    // in the same grey paragraph.
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                            .padding(.top, 3)

                        Text(issue.fix)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(AppTheme.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .padding(.top, 9)
            }
            .padding(14)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var moreButton: some View {
        Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) { expanded = true }
        } label: {
            HStack(spacing: 6) {
                Text("Show \(hidden) more")
                    .font(.system(size: 13, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Preview

#Preview("Issues") {
    let anchor = Date()

    return ScrollView {
        VStack(spacing: 18) {
            ItineraryIssueCard(state: .checking, issues: [], bookingCount: 6) { _ in }

            ItineraryIssueCard(state: .done(usedFallback: false), issues: [], bookingCount: 6) { _ in }

            ItineraryIssueCard(
                state: .done(usedFallback: false),
                issues: [
                    ItineraryIssue(
                        severity: .likelyWrong,
                        symbol: "clock.badge.exclamationmark",
                        headline: "Tight run to Eurostar to London",
                        problem: "Louvre Museum is likely to finish around 4:00 PM, about 20 minutes before Eurostar to London leaves at 4:20 PM.",
                        fix: "That leaves nothing for getting to the platform — move Louvre Museum earlier, or take a later train.",
                        itemIDs: [UUID()],
                        origin: .rules,
                        anchor: anchor
                    ),
                    ItineraryIssue(
                        severity: .worthChecking,
                        symbol: "lightbulb.max.fill",
                        headline: "Sacré-Cœur booked after closing",
                        problem: "The basilica stops admitting visitors in the early evening, and this is booked for late at night.",
                        fix: "Move Sacré-Cœur to the afternoon of the same day.",
                        itemIDs: [UUID()],
                        origin: .intelligence,
                        anchor: anchor
                    ),
                    ItineraryIssue(
                        severity: .worthChecking,
                        symbol: "doc.on.doc.fill",
                        headline: "Seine dinner cruise is on the plan twice",
                        problem: "2 bookings called Seine dinner cruise sit on Thu 14 May. A document read from a table that ran over a page break usually produces this.",
                        fix: "Delete the spare, unless you really did book it twice.",
                        itemIDs: [UUID()],
                        origin: .rules,
                        anchor: anchor
                    )
                ],
                bookingCount: 9
            ) { _ in }

            ItineraryIssueCard(
                state: .done(usedFallback: true),
                issues: [
                    ItineraryIssue(
                        severity: .worthChecking,
                        symbol: "bed.double.circle.fill",
                        headline: "No stay for the first 2 nights",
                        problem: "The plan starts on Mon 11 May but the first stay, Hôtel Malte Opera, checks in on Wed 13 May.",
                        fix: "Add where you're sleeping until then, or move the check-in earlier if it's already booked.",
                        itemIDs: [UUID()],
                        origin: .rules,
                        anchor: anchor
                    )
                ],
                bookingCount: 5
            ) { _ in }
        }
        .padding(20)
    }
    .background { CanvasBackground() }
}
