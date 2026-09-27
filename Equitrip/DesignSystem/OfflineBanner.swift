//
//  OfflineBanner.swift
//  Equitrip
//

import SwiftUI

/// The pill above the tab bar that says the app is working without a
/// connection, what that means for what you're looking at, and when it's
/// caught up again.
///
/// It's the tab bar's bottom accessory rather than a strip at the top of the
/// screen. At the top it pushed every screen's header down, or covered it.
/// Down here it sits where the thumb already is. When the tab bar minimizes
/// on scroll, it slides in beside the collapsed bar at one line, so a long
/// ledger never loses a row to it.
///
/// It keeps talking until the queue is empty. Coming back online isn't the
/// same as the changes made offline having arrived, and the moment someone
/// is most likely to check is right after an expense they logged on a plane.
struct OfflineBanner: View {
    @State private var network = NetworkMonitor.shared
    @State private var outbox = OfflineOutbox.shared
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    @State private var dismissTask: Task<Void, Never>?

    enum Phase: Equatable {
        case hidden
        case offline(pending: Int)
        case syncing(pending: Int)
        case synced
        case stalled(pending: Int)

        var isOffline: Bool { if case .offline = self { true } else { false } }
        var isSyncing: Bool { if case .syncing = self { true } else { false } }
        var isStalled: Bool { if case .stalled = self { true } else { false } }
    }

    /// What there is to say right now. Static so `RootTabView` can switch
    /// the accessory off entirely when there's nothing, rather than leaving
    /// an empty pill above the tab bar.
    static var phase: Phase {
        let network = NetworkMonitor.shared
        let outbox = OfflineOutbox.shared
        let pending = outbox.pendingChanges
        if !network.isOnline { return .offline(pending: pending) }
        // Set when the connection drops, cleared a moment after everything
        // queued while offline has gone up. It's what lets the pill say
        // "back online" at all, instead of just disappearing.
        if network.isRecovering {
            return outbox.isFlushing || pending > 0 ? .syncing(pending: pending) : .synced
        }
        if outbox.isStalled, pending > 0 { return .stalled(pending: pending) }
        return .hidden
    }

    private var phase: Phase { Self.phase }

    private var isInline: Bool { placement == .inline }

    var body: some View {
        Button {
            guard phase.isStalled else { return }
            Task { await outbox.flush() }
        } label: {
            Group {
                if isInline { inline } else { expanded }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: phase)
        .accessibilityElement(children: .combine)
        .accessibilityHint(phase.isStalled ? "Tries sending them again" : "")
        .onChange(of: phase) { _, phase in
            announce(phase)
            dismissTask?.cancel()
            guard phase == .synced else { return }
            dismissTask = Task {
                try? await Task.sleep(for: .seconds(2.4))
                guard !Task.isCancelled else { return }
                network.finishRecovery()
            }
        }
    }

    // MARK: - Layouts

    /// Above the tab bar: the whole sentence.
    private var expanded: some View {
        HStack(spacing: 11) {
            badge(size: 34)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .contentTransition(.opacity)

                Text(subtitle)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .contentTransition(.numericText())
            }

            Spacer(minLength: 4)

            trailing
        }
        .padding(.leading, 10)
        .padding(.trailing, 12)
    }

    /// Beside the minimized tab bar: one line, the part that matters.
    private var inline: some View {
        HStack(spacing: 8) {
            badge(size: 26)

            Text(inlineTitle)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .contentTransition(.numericText())

            Spacer(minLength: 0)
        }
        // The badge is inset from the pill's left edge by the same gap as
        // from its top and bottom, so it sits centred in the rounded end.
        .padding(.leading, 11)
        .padding(.trailing, 12)
    }

    private func badge(size: CGFloat) -> some View {
        ZStack {
            // Solid, with a white glyph: a wash of the tint disappeared into
            // the glass over a dark photograph.
            Circle()
                .fill(tint)

            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
                .contentTransition(.symbolEffect(.replace.downUp))
                .symbolEffect(.rotate, options: .repeat(.continuous), isActive: phase.isSyncing)
                .symbolEffect(.pulse, options: .repeat(.periodic(delay: 1.6)), isActive: phase.isOffline)
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var trailing: some View {
        switch phase {
        case .offline(let pending) where pending > 0:
            HStack(spacing: 4) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10.5, weight: .bold))
                Text("\(pending)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .contentTransition(.numericText(value: Double(pending)))
            }
            .foregroundStyle(Palette.amberDeep)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Palette.amber.opacity(0.16), in: .capsule)
            .accessibilityHidden(true)

        case .stalled:
            Text("Retry")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.accent.opacity(0.1), in: .capsule)

        default:
            EmptyView()
        }
    }

    // MARK: - Words

    private var title: String {
        switch phase {
        case .hidden, .offline: "You're offline"
        case .syncing, .synced: "Back online"
        case .stalled: "Changes not synced yet"
        }
    }

    private var subtitle: String {
        switch phase {
        case .offline(let pending):
            pending == 0
                ? "Showing trips saved on this phone"
                : "\(pending.pluralised("change")) saved here · will sync"
        case .syncing(let pending):
            pending == 0 ? "Syncing…" : "Syncing \(pending.pluralised("change"))…"
        case .synced:
            "Everything's up to date"
        case .stalled(let pending):
            "\(pending.pluralised("change")) waiting to go up"
        case .hidden:
            ""
        }
    }

    private var inlineTitle: String {
        switch phase {
        case .hidden, .offline(0): "You're Offline"
        case .offline(let pending): "Offline · \(pending) to sync"
        case .syncing(let pending): pending == 0 ? "Syncing…" : "Syncing \(pending)…"
        case .synced: "Up to date"
        case .stalled(let pending): "\(pending) not synced · Retry"
        }
    }

    private var symbol: String {
        switch phase {
        case .hidden, .offline: "wifi.slash"
        case .syncing: "arrow.triangle.2.circlepath"
        case .synced: "checkmark"
        case .stalled: "icloud.slash"
        }
    }

    private var tint: Color {
        switch phase {
        case .hidden, .offline, .stalled: Palette.yellow
        case .syncing: AppTheme.accent
        case .synced: AppTheme.positive
        }
    }

    private func announce(_ phase: Phase) {
        guard phase != .hidden else { return }
        AccessibilityNotification.Announcement("\(title). \(subtitle)").post()
    }
}
