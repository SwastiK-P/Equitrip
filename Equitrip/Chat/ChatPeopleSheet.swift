//
//  ChatPeopleSheet.swift
//  Equitrip
//

import SwiftUI

/// Who's in the conversation, and whether they're keeping up with it.
///
/// Opened from the faces in the chat header. The question behind that tap is
/// rarely "who's on this trip" — the trip screen answers that — it's "has Kim
/// even seen this?", so each row leads with how far that person has read, and
/// offers the quickest way to get their attention: an @-mention.
struct ChatPeopleSheet: View {
    let trip: Trip
    let chat: ChatService
    var onMention: (Traveller) -> Void
    var onInvite: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ChatSheetHeader(title: "People", caption: caption)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    group(nil, people: members)

                    if !invited.isEmpty {
                        group("Invited", people: invited)
                    }

                    if !departed.isEmpty {
                        group("Left the trip", people: departed)
                    }

                    Button(action: onInvite) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 36, height: 36)
                                .background(AppTheme.accent.opacity(0.1), in: .circle)
                            Text("Invite someone")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppTheme.ink)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.inkTertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .contentShape(.rect)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .cardSurface(corner: 18, shadow: 4)
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

    // MARK: Groups

    private var members: [Traveller] {
        let current = trip.travellers.filter { !trip.invitedIDs.contains($0.id) && !trip.hasLeft($0.id) }
        // You first, then everyone else by name.
        return current.filter { $0.id == Traveller.you.id }
            + current.filter { $0.id != Traveller.you.id }.sorted { $0.name < $1.name }
    }

    private var invited: [Traveller] { trip.travellers.filter { trip.invitedIDs.contains($0.id) } }
    private var departed: [Traveller] { trip.travellers.filter { trip.hasLeft($0.id) && !trip.invitedIDs.contains($0.id) } }

    private var caption: String {
        let others = members.filter { $0.id != Traveller.you.id }
        guard !others.isEmpty else { return "Just you so far" }
        let caughtUp = others.filter { readState(of: $0) == .caughtUp }.count
        if caughtUp == others.count { return "Everyone's caught up" }
        return "\(caughtUp) of \(others.count) caught up"
    }

    private func group(_ title: String?, people: [Traveller]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .padding(.horizontal, 4)
            }

            VStack(spacing: 0) {
                ForEach(people) { person in
                    row(person)
                    if person.id != people.last?.id { Hairline(inset: 60) }
                }
            }
            .cardSurface(corner: 18, shadow: 4)
        }
    }

    // MARK: Row

    private func row(_ person: Traveller) -> some View {
        let isYou = person.id == Traveller.you.id
        let isInvited = trip.invitedIDs.contains(person.id)
        let hasLeft = trip.hasLeft(person.id)
        let isTyping = chat.typingPeople.contains { $0.id == person.id }

        return HStack(spacing: 12) {
            TravellerAvatar(traveller: person, size: 36, isDimmed: hasLeft || isInvited)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(isYou ? "\(person.name) (you)" : person.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)

                    if trip.organiserIDs.contains(person.id) {
                        TagChip(title: "Organiser", tint: AppTheme.accent)
                    }
                }

                Text(status(of: person, isYou: isYou, isInvited: isInvited, hasLeft: hasLeft, isTyping: isTyping))
                    .font(.system(size: 12.5))
                    .foregroundStyle(isTyping ? AppTheme.accent : AppTheme.inkSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            if !isYou, !isInvited {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onMention(person)
                } label: {
                    Image(systemName: "at")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.accent.opacity(0.1), in: .circle)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Mention \(person.name)")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func status(of person: Traveller, isYou: Bool, isInvited: Bool, hasLeft: Bool, isTyping: Bool) -> String {
        if isTyping { return "typing…" }
        if isInvited { return "Hasn't joined yet" }
        if isYou { return person.email ?? "On this trip" }

        let reading: String
        switch readState(of: person) {
        case .caughtUp: reading = "Seen everything"
        case .behind(let since): reading = "Last read \(since.formatted(.relative(presentation: .named)))"
        case .never: reading = "Hasn't opened the chat"
        }

        if hasLeft, let departure = trip.departure(for: person.id) {
            return "Left \(DateFormatter.cached("d MMM").string(from: departure.leftAt)) · \(reading)"
        }
        return reading
    }

    // MARK: Reading

    private enum ReadState: Equatable {
        case caughtUp
        case behind(Date)
        case never
    }

    private func readState(of person: Traveller) -> ReadState {
        guard let readAt = chat.readPositions[person.id] else { return .never }
        guard let newest = chat.messages.last(where: { $0.delivery == .sent && $0.authorID != person.id }) else {
            return .caughtUp
        }
        // A second's grace, matching `ChatService.readMarkers`: read positions
        // are stamped with a message's own time and can round just short of it.
        return readAt.addingTimeInterval(1) >= newest.sentAt ? .caughtUp : .behind(readAt)
    }
}
