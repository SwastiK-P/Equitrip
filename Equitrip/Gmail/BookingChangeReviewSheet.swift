//
//  BookingChangeReviewSheet.swift
//  Equitrip
//

import SwiftUI

/// The moment a booking change is found: it comes forward and asks.
///
/// Nothing a travel company emails changes the plan quietly. Each change is
/// put in front of the person one at a time, with what the app will do about
/// it, and waits for Confirm — or, with "Apply changes automatically" on and
/// a match that leaves no doubt, runs the same steps by itself while they
/// watch. Either way the person sees every change happen.
///
/// Presented by `RootTabView`, above whichever tab is showing, and walks the
/// queue: when one is finished the next one slides in.
struct BookingChangeReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tripStore) private var store
    @Environment(\.bookingChanges) private var changes
    @Environment(\.bookingChangeSync) private var sync

    let firstID: String
    /// "Not now" on one of them — kept by the root so it isn't asked again this session.
    var snooze: (String) -> Void

    @State private var currentID: String?
    @State private var handledHere: [String] = []

    private var current: BookingChange? { changes.change(currentID ?? firstID) }

    /// Waiting ones still to show after this, for the "1 of 3" line.
    private var remaining: Int {
        changes.waiting().filter { $0.id != (currentID ?? firstID) && !handledHere.contains($0.id) }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let current {
                    BookingChangeCard(
                        change: current,
                        runsAutomatically: sync?.appliesAutomatically == true,
                        apply: {
                            BookingChangeApplier.apply(current, store: store, changes: changes,
                                                       postToChat: sync?.postsToChat ?? true,
                                                       automatically: sync?.appliesAutomatically == true)
                        },
                        undo: {
                            if let updated = changes.change(current.id) {
                                BookingChangeApplier.undo(updated, store: store, changes: changes)
                                changes.dismiss(current.id)
                            }
                        },
                        dismissChange: {
                            snooze(current.id)
                            advance(from: current.id)
                        },
                        choose: { candidate in withAnimation(.snappy) { changes.choose(candidate, for: current.id) } },
                        finished: { advance(from: current.id) }
                    )
                    .id(current.id)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) { header }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground { CanvasBackground() }
        .onAppear { changes.markAllSeen() }
    }

    private func advance(from id: String) {
        handledHere.append(id)
        let next = changes.waiting().first { !handledHere.contains($0.id) && $0.id != id }
        withAnimation(.snappy(duration: 0.4)) {
            if let next { currentID = next.id } else { dismiss() }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Spotted in your mail")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text(remaining == 0 ? "A booking changed" : "\(remaining) more after this one")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .contentTransition(.numericText())
            }
            Spacer(minLength: 8)
            CircleGlyphButton(symbol: "xmark", size: 34) {
                if let id = currentID ?? Optional(firstID), changes.change(id)?.status.isWaiting == true { snooze(id) }
                dismiss()
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}
