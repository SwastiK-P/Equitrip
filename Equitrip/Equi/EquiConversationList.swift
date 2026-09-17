//
//  EquiConversationList.swift
//  Equitrip
//

import SwiftUI

/// Equi's past conversations as shelved rows — the body of the history sheet
/// on a phone, and the whole of the sidebar on a wide iPad.
///
/// Lifted out of `EquiHistorySheet` so the two are one list rather than two
/// copies of the shelving and the delete confirmation. The list doesn't scroll
/// or dismiss anything itself: the sheet closes after opening a thread and the
/// sidebar stays put, and each host owns its own scroll view and margins.
struct EquiConversationList: View {
    let history: EquiHistoryStore
    /// The thread on screen, highlighted. Only the sidebar passes one — in the
    /// sheet the current thread is the screen underneath it.
    var selectedID: UUID?
    var onOpen: (EquiConversationSummary) -> Void

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 18) {
            if history.conversations.isEmpty {
                emptyState
            } else {
                ForEach(groups, id: \.title) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.inkTertiary)
                            .textCase(.uppercase)
                            .padding(.leading, 4)

                        VStack(spacing: 8) {
                            ForEach(group.conversations) { conversation in
                                row(conversation)
                            }
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: history.conversations)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: selectedID)
    }

    // MARK: - Rows

    private func row(_ conversation: EquiConversationSummary) -> some View {
        SwipeToDelete(onDelete: { delete(conversation) }) {
            openButton(conversation)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    /// Straight away, no confirmation: a conversation with Equi can be asked
    /// again in a second, and a dialog in front of every swipe made clearing
    /// out the list a chore. The swipe or the menu is the intent.
    private func delete(_ conversation: EquiConversationSummary) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { await history.delete(conversation) }
    }

    private func openButton(_ conversation: EquiConversationSummary) -> some View {
        let isSelected = conversation.id == selectedID

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onOpen(conversation)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? .white : AppTheme.accent)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? AppTheme.accent : AppTheme.accent.opacity(0.12), in: .circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text(conversation.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(caption(for: conversation))
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.inkTertiary)
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary.opacity(0.7))
                    .opacity(isSelected ? 0 : 1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(.rect)
            .cardSurface(corner: 16, shadow: 3)
            // A ring rather than a filled row: the row's text stays the same
            // ink either way, so selecting a thread never changes how it reads.
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppTheme.accent.opacity(0.55), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .contextMenu {
            Button(role: .destructive) { delete(conversation) } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(AppTheme.accent.opacity(0.55))

            Text(history.isLoadingList ? "Loading…" : "Nothing here yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            Text("Ask Equi about a trip and the conversation is kept here, on every device you're signed in on.")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.inkTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 24)
    }

    // MARK: - Shelving

    private struct Group {
        let title: String
        let conversations: [EquiConversationSummary]
    }

    /// Newest first within each shelf, shelves in the order the conversations
    /// already arrive in — so the grouping never reorders the list, it only
    /// puts headings through it.
    private var groups: [Group] {
        var order: [String] = []
        var buckets: [String: [EquiConversationSummary]] = [:]

        for conversation in history.conversations {
            let key = shelf(for: conversation.updatedAt)
            if buckets[key] == nil { order.append(key) }
            buckets[key, default: []].append(conversation)
        }

        return order.map { Group(title: $0, conversations: buckets[$0] ?? []) }
    }

    private func shelf(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        if let week = calendar.date(byAdding: .day, value: -7, to: .now), date > week { return "This week" }
        if calendar.isDate(date, equalTo: .now, toGranularity: .year) {
            return DateFormatter.cached("MMMM").string(from: date)
        }
        return DateFormatter.cached("MMMM yyyy").string(from: date)
    }

    /// The time for a thread spoken to today, the date for an older one —
    /// "14:32" is useful on something from an hour ago and meaningless on
    /// something from March.
    private func caption(for conversation: EquiConversationSummary) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(conversation.updatedAt) {
            return DateFormatter.cached("HH:mm").string(from: conversation.updatedAt)
        }
        if calendar.isDate(conversation.updatedAt, equalTo: .now, toGranularity: .year) {
            return DateFormatter.cached("d MMM").string(from: conversation.updatedAt)
        }
        return DateFormatter.cached("d MMM yyyy").string(from: conversation.updatedAt)
    }
}
