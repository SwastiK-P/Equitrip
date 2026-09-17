//
//  ChatMessageInfoSheet.swift
//  Equitrip
//

import SwiftUI

/// Who has seen a message.
///
/// "Did everyone see the ferry moved to 9?" is a question a group chat is
/// constantly asked, and the avatars under the thread only answer it for the
/// latest message. This answers it for any of them, including who hasn't.
struct ChatMessageInfoSheet: View {
    let message: ChatMessage
    let chat: ChatService
    let trip: Trip

    var body: some View {
        VStack(spacing: 0) {
            ChatSheetHeader(title: "Message info")

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summary

                    section("Seen by") {
                        if seen.isEmpty {
                            placeholder("Nobody yet")
                        } else {
                            ForEach(seen) { personRow($0, trailing: nil) }
                        }
                    }

                    if !unseen.isEmpty {
                        section("Not seen yet") {
                            ForEach(unseen) { personRow($0, trailing: nil) }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
    }

    private var seen: [Traveller] { chat.seen(message) }

    /// Everyone on the trip who could have read it and hasn't — not the
    /// author, not anyone still only invited.
    private var unseen: [Traveller] {
        let seenIDs = Set(seen.map(\.id))
        return trip.travellers.filter {
            $0.id != message.authorID && $0.id != Traveller.you.id && !seenIDs.contains($0.id) && !trip.invitedIDs.contains($0.id)
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(message.preview)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(4)

            Hairline()

            infoLine("Sent", "\(chat.authorName(of: message)) · \(DateFormatter.cached("EEE d MMM, h:mm a").string(from: message.sentAt))")
            if let edited = message.editedAt {
                infoLine("Edited", DateFormatter.cached("EEE d MMM, h:mm a").string(from: edited))
            }
            if message.isPinned {
                infoLine("Pinned", message.pinnedByID.flatMap(chat.traveller).map { $0.id == Traveller.you.id ? "by you" : "by \($0.name)" } ?? "Yes")
            }
        }
        .padding(14)
        .cardSurface(corner: 18, shadow: 4)
    }

    private func infoLine(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkSecondary)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(AppTheme.inkSecondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) { content() }
                .cardSurface(corner: 18, shadow: 4)
        }
    }

    private func personRow(_ person: Traveller?, trailing: String?) -> some View {
        HStack(spacing: 11) {
            if let person {
                TravellerAvatar(traveller: person, size: 30)
            }
            Text(person.map { $0.id == Traveller.you.id ? "You" : $0.name } ?? "Someone")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.ink)
            Spacer(minLength: 6)
            if let trailing {
                Text(trailing).font(.system(size: 20))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(AppTheme.inkTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
    }
}
