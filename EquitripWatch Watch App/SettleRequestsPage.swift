//
//  SettleRequestsPage.swift
//  EquitripWatch Watch App
//

import SwiftUI

/// Every "I paid you" waiting on your answer, across every trip — the watch's
/// version of Home's pending-settlements card.
struct SettleRequestsPage: View {
    @Environment(WatchStore.self) private var store

    var body: some View {
        let open = store.openRequests
        let queued = store.queuedRequests

        Group {
            if open.isEmpty && queued.isEmpty {
                WatchNotice(
                    symbol: "checkmark.seal.fill",
                    title: "All caught up",
                    detail: "When someone says they've paid you, you can confirm it here."
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        if !open.isEmpty {
                            HStack(spacing: 5) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.caption2)
                                Eyebrow(text: open.count == 1 ? "1 waiting on you" : "\(open.count) waiting on you")
                            }
                            .foregroundStyle(Brand.accent)
                            .padding(.horizontal, 2)

                            ForEach(open) { request in
                                NavigationLink {
                                    SettleRequestDetail(request: request)
                                } label: {
                                    RequestRow(request: request)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if !queued.isEmpty {
                            Eyebrow(text: "Waiting for iPhone", tint: Brand.inkTertiary)
                                .padding(.horizontal, 2)
                                .padding(.top, open.isEmpty ? 0 : 8)

                            ForEach(queued) { request in
                                RequestRow(request: request, isQueued: true)
                            }

                            Text("Sent. These go through when your iPhone is nearby.")
                                .font(.caption2)
                                .foregroundStyle(Brand.inkTertiary)
                                .padding(.horizontal, 2)
                        }
                    }
                }
            }
        }
        .navigationTitle("Settle")
        .watchPageTint(store.openRequests.isEmpty ? Brand.positive : Brand.accent)
    }
}

// MARK: - Row

private struct RequestRow: View {
    let request: EquitripSnapshot.SettleRequest
    var isQueued = false

    var body: some View {
        HStack(spacing: 8) {
            InitialDisc(name: request.fromName)

            VStack(alignment: .leading, spacing: 1) {
                Text(request.fromName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Brand.ink)
                Text(isQueued ? "Answer queued" : "paid you · \(request.methodLabel)")
                    .font(.caption2)
                    .foregroundStyle(Brand.inkSecondary)
                Text(request.tripTitle)
                    .font(.caption2)
                    .foregroundStyle(Brand.inkTertiary)
            }
            .lineLimit(1)
            .layoutPriority(1)

            Spacer(minLength: 2)

            Text(request.amountLabel)
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(isQueued ? Brand.inkSecondary : Brand.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .watchCard()
        .opacity(isQueued ? 0.6 : 1)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Detail

/// The request in full, and the two answers. Declining asks first: telling
/// someone their payment never arrived is not a thing to do by brushing the
/// wrong button.
///
/// Two full-width text buttons, stacked — the layout HIG's rule for watch,
/// and the only arrangement where neither answer is the easy one to hit by
/// accident.
struct SettleRequestDetail: View {
    let request: EquitripSnapshot.SettleRequest

    @Environment(WatchStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDecline = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                VStack(spacing: 4) {
                    InitialDisc(name: request.fromName, style: .title3)

                    Text("\(request.fromName) says they paid you")
                        .font(.footnote)
                        .foregroundStyle(Brand.inkSecondary)
                        .multilineTextAlignment(.center)

                    Text(request.amountLabel)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(Brand.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    HStack(spacing: 4) {
                        Image(systemName: request.methodSymbol)
                        Text(request.methodLabel)
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Brand.accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Brand.accent.opacity(0.18), in: .capsule)

                    Text(request.tripTitle)
                        .font(.caption2)
                        .foregroundStyle(Brand.inkTertiary)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity)

                if !request.note.isEmpty {
                    Text("“\(request.note)”")
                        .font(.footnote)
                        .italic()
                        .foregroundStyle(Brand.ink)
                        .watchCard()
                }

                Button {
                    answer(confirm: true)
                } label: {
                    // Dark on the mint, not white — the watch's positive is
                    // the light dark-mode green, and white on it washes out.
                    Label("Confirm", systemImage: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Brand.ctaLabel)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Brand.positive)

                Button(role: .destructive) {
                    confirmingDecline = true
                } label: {
                    Text("Not received")
                        .font(.footnote.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                // The app-wide accent tint would otherwise win over the
                // destructive role and paint a "no" the colour of a "yes".
                .tint(Brand.danger)
                .foregroundStyle(Brand.danger)
            }
        }
        .watchPageTint(Brand.accent)
        .confirmationDialog(
            "Tell \(request.fromName) you haven't received \(request.amountLabel)?",
            isPresented: $confirmingDecline,
            titleVisibility: .visible
        ) {
            Button("Not received", role: .destructive) { answer(confirm: false) }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func answer(confirm: Bool) {
        store.respond(to: request, confirm: confirm)
        dismiss()
    }
}

#Preview {
    NavigationStack { SettleRequestsPage() }
        .environment(WatchStore(preview: .placeholder))
}
