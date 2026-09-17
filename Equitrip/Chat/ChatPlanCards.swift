//
//  ChatPlanCards.swift
//  Equitrip
//

import SwiftUI

// MARK: - Poll

/// A question the group answers by tapping, with the tally in the card.
///
/// "Reply 1 for the early ferry" in a thread of forty messages is a vote
/// nobody can count. Here every answer is one row per person, so the result is
/// always the current one and changing your mind replaces your vote rather
/// than adding a second.
struct ChatPollCard: View {
    let message: ChatMessage
    let poll: ChatAttachment.Poll
    let trip: Trip
    let chat: ChatService

    var body: some View {
        let mine = chat.myChoices(for: message)
        let turnout = chat.respondents(to: message)
        let leading = leadingOptionIDs

        ChatCardFrame {
            VStack(alignment: .leading, spacing: 11) {
                ChatCardEyebrow(
                    symbol: "chart.bar",
                    title: "Poll",
                    trailing: poll.allowsMultiple ? "Pick any" : "Pick one"
                )

                Text(poll.question)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 7) {
                    ForEach(poll.options) { option in
                        optionRow(
                            option,
                            isMine: mine.contains(option.id),
                            isLeading: turnout > 0 && leading.contains(option.id),
                            turnout: turnout
                        )
                    }
                }

                Text(turnoutLabel(turnout))
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .padding(14)
        }
        .disabled(message.delivery != .sent)
    }

    private func optionRow(_ option: ChatAttachment.Option, isMine: Bool, isLeading: Bool, turnout: Int) -> some View {
        let voters = chat.people(choosing: option.id, on: message)
        let share = turnout == 0 ? 0 : Double(voters.count) / Double(turnout)

        return Button {
            Task { await chat.vote(option.id, on: message) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isMine ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isMine ? AppTheme.accent : AppTheme.inkTertiary)
                    .contentTransition(.symbolEffect(.replace))

                Text(option.text)
                    .font(.system(size: 14, weight: isLeading ? .semibold : .regular))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 4)

                if !voters.isEmpty {
                    AvatarStack(travellers: voters, size: 16, max: 3)
                    Text("\(voters.count)")
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .foregroundStyle(AppTheme.inkSecondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(alignment: .leading) {
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(AppTheme.accent.opacity(isMine ? 0.16 : 0.08))
                        .frame(width: max(0, proxy.size.width * share))
                }
            }
            .background(AppTheme.canvasTop.opacity(0.45), in: .rect(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(isMine ? AppTheme.accent.opacity(0.4) : AppTheme.cardStroke.opacity(0.06))
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: share)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("\(option.text), \(voters.count) \(voters.count == 1 ? "vote" : "votes")")
        .accessibilityAddTraits(isMine ? .isSelected : [])
    }

    private var leadingOptionIDs: Set<String> {
        let counts = poll.options.map { ($0.id, chat.people(choosing: $0.id, on: message).count) }
        let top = counts.map(\.1).max() ?? 0
        return top == 0 ? [] : Set(counts.filter { $0.1 == top }.map(\.0))
    }

    private func turnoutLabel(_ turnout: Int) -> String {
        let people = trip.travellers.filter { !trip.invitedIDs.contains($0.id) }.count
        if turnout == 0 { return "No votes yet" }
        if turnout >= people { return "Everyone's voted" }
        return "\(turnout) of \(people) voted"
    }
}

// MARK: - Meetup

/// "Lobby at 7, then dinner" — a time, maybe a place, and who's coming.
struct ChatMeetupCard: View {
    let message: ChatMessage
    let meetup: ChatAttachment.Meetup
    let chat: ChatService

    var body: some View {
        let mine = chat.myChoices(for: message).first.flatMap(ChatAttachment.RSVP.init(rawValue:))
        let going = chat.people(choosing: ChatAttachment.RSVP.going.rawValue, on: message)

        ChatCardFrame {
            VStack(alignment: .leading, spacing: 12) {
                ChatCardEyebrow(symbol: "calendar", title: "Meetup", tint: Palette.violet, trailing: relativeLabel)

                HStack(spacing: 12) {
                    dateTile

                    VStack(alignment: .leading, spacing: 2) {
                        Text(meetup.title)
                            .font(.system(size: 15.5, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(2)
                        Text(DateFormatter.cached("EEEE · h:mm a").string(from: meetup.date))
                            .font(.system(size: 12.5))
                            .foregroundStyle(AppTheme.inkSecondary)
                        if let place = meetup.place, !place.isEmpty {
                            Label(place, systemImage: "mappin")
                                .font(.system(size: 12.5))
                                .foregroundStyle(AppTheme.inkSecondary)
                                .lineLimit(1)
                        }
                    }
                    .multilineTextAlignment(.leading)
                }

                HStack(spacing: 6) {
                    ForEach(ChatAttachment.RSVP.allCases) { answer in
                        rsvpButton(answer, isMine: mine == answer)
                    }
                }

                if !going.isEmpty {
                    HStack(spacing: 6) {
                        AvatarStack(travellers: going, size: 20, max: 5)
                        Text(going.count == 1 ? "\(going[0].id == Traveller.you.id ? "You're" : "\(going[0].name)'s") going" : "\(going.count) going")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.inkSecondary)
                    }
                }
            }
            .padding(14)
        }
        .disabled(message.delivery != .sent)
    }

    private var dateTile: some View {
        VStack(spacing: 0) {
            Text(DateFormatter.cached("MMM").string(from: meetup.date).uppercased())
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2.5)
                .background(Palette.violet)
            Text(DateFormatter.cached("d").string(from: meetup.date))
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .frame(maxHeight: .infinity)
        }
        .frame(width: 44, height: 46)
        .background(AppTheme.card)
        .clipShape(.rect(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppTheme.cardStroke.opacity(0.1))
        }
    }

    private func rsvpButton(_ answer: ChatAttachment.RSVP, isMine: Bool) -> some View {
        let count = chat.people(choosing: answer.rawValue, on: message).count

        return Button {
            Task { await chat.rsvp(answer, to: message) }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: answer.symbol)
                    .font(.system(size: 11, weight: .bold))
                Text(answer.label)
                    .font(.system(size: 12.5, weight: .semibold))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11.5, weight: .semibold).monospacedDigit())
                        .opacity(0.8)
                }
            }
            .foregroundStyle(isMine ? .white : answer.tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isMine ? answer.tint : answer.tint.opacity(0.1), in: .capsule)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(isMine ? .isSelected : [])
    }

    /// "in 3 hours", "tomorrow", "2 days ago" — the one thing people actually
    /// need from a meetup time glanced at mid-scroll.
    private var relativeLabel: String {
        let interval = meetup.date.timeIntervalSinceNow
        if abs(interval) < 15 * 60 { return "Now" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: meetup.date, relativeTo: Date())
    }
}

// MARK: - Bring list

/// What the group needs, and who's said they've got each thing.
///
/// Per person, not a shared tick box: "done" on a packing list is only useful
/// if you know who did it, and two people can each cover the same item without
/// one quietly un-ticking the other.
struct ChatChecklistCard: View {
    let message: ChatMessage
    let list: ChatAttachment.Checklist
    let chat: ChatService

    var body: some View {
        let mine = Set(chat.myChoices(for: message))
        let covered = list.items.filter { !chat.people(choosing: $0.id, on: message).isEmpty }.count

        ChatCardFrame {
            VStack(alignment: .leading, spacing: 11) {
                ChatCardEyebrow(
                    symbol: "checklist",
                    title: "Bring list",
                    tint: Palette.green,
                    trailing: "\(covered) of \(list.items.count) covered"
                )

                Text(list.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                ProgressView(value: Double(covered), total: Double(max(list.items.count, 1)))
                    .tint(Palette.green)
                    .animation(.spring(response: 0.4), value: covered)

                VStack(spacing: 2) {
                    ForEach(list.items) { item in
                        itemRow(item, isMine: mine.contains(item.id))
                    }
                }
            }
            .padding(14)
        }
        .disabled(message.delivery != .sent)
    }

    private func itemRow(_ item: ChatAttachment.Option, isMine: Bool) -> some View {
        let people = chat.people(choosing: item.id, on: message)

        return Button {
            Task { await chat.toggleCovered(item.id, on: message) }
        } label: {
            HStack(spacing: 9) {
                Image(systemName: isMine ? "checkmark.square.fill" : (people.isEmpty ? "square" : "checkmark.square"))
                    .font(.system(size: 17))
                    .foregroundStyle(isMine || !people.isEmpty ? Palette.green : AppTheme.inkTertiary)
                    .contentTransition(.symbolEffect(.replace))

                Text(item.text)
                    .font(.system(size: 14))
                    .foregroundStyle(people.isEmpty ? AppTheme.ink : AppTheme.inkSecondary)
                    .strikethrough(!people.isEmpty, color: AppTheme.inkTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 4)

                if !people.isEmpty {
                    AvatarStack(travellers: people, size: 18, max: 3)
                }
            }
            .padding(.vertical, 6)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(people.isEmpty ? "\(item.text), not covered" : "\(item.text), covered by \(people.map(\.name).formatted(.list(type: .and)))")
    }
}
