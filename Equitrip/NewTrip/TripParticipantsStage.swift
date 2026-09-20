//
//  TripParticipantsStage.swift
//  Equitrip
//

import SwiftUI

/// "Your document says four people. Who are they?"
///
/// This screen exists because of the one thing an importer must never do. The
/// Paris itinerary says `TRAVELERS 4 people` and never writes a single name,
/// and the previous version filled that silence in with names — plausible ones,
/// invented ones — which then went onto a shared ledger and started owing each
/// other money. A headcount is a fact; who those people are is a question.
///
/// It asks for the question's real answer: an email address. A name typed into
/// a box is a label — two spellings make two people, neither of whom can be
/// told anything. An address resolves to an actual Equitrip account, whose name
/// and face come back from the server rather than from the keyboard; and when
/// it doesn't resolve, it becomes an invitation that the same address claims on
/// signup. Either way nobody's name is ever guessed, by the model or by us.
struct TripParticipantsStage: View {
    @Binding var draft: TripDraft
    var onContinue: () -> Void

    @State private var entry = ""
    @State private var rows: [Row] = []
    @State private var lookupError: String?
    @State private var isResolving = false
    @State private var appeared = false
    @FocusState private var entryFocused: Bool

    /// One address that has been resolved, or is being resolved.
    private struct Row: Identifiable, Equatable {
        var id: String { email }
        let email: String
        var state: State

        enum State: Equatable {
            case resolving
            case member(Traveller)
            case invited(Traveller)
            case failed(String)
        }

        var traveller: Traveller? {
            switch state {
            case .member(let person), .invited(let person): person
            case .resolving, .failed: nil
            }
        }

        var isInvited: Bool {
            if case .invited = state { return true }
            return false
        }
    }

    private var expected: Int { max(draft.expectedTravellerCount, rows.count + 1) }
    private var filled: Int { 1 + rows.filter { $0.traveller != nil }.count }
    private var everyoneAdded: Bool { filled >= expected }
    private var canAdd: Bool {
        TravellerDirectory.isPlausible(entry)
            && !rows.contains { $0.email == TravellerDirectory.normalise(entry) }
            && TravellerDirectory.normalise(entry) != CurrentUser.traveller.email
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headline
                    .padding(.bottom, 22)
                    .staggered(0, appeared)

                addField
                    .staggered(1, appeared)

                if !draft.namesFromDocument.isEmpty {
                    documentNames
                        .padding(.top, 12)
                        .staggered(2, appeared)
                }

                roster
                    .padding(.top, 14)
                    .staggered(3, appeared)

                note
                    .padding(.top, 18)
                    .staggered(4, appeared)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { continueBar }
        .animation(.spring(response: 0.4, dampingFraction: 0.84), value: rows)
        .onAppear(perform: prepare)
    }

    // MARK: - Headline

    private var headline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Who's coming?")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text(prompt)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Says where the number came from. "We think there are four of you" is a
    /// guess; "your itinerary says four" is a citation, and the difference is
    /// whether someone trusts the rest of the screen.
    private var prompt: String {
        guard draft.expectedTravellerCount > 1 else {
            return "Add everyone sharing the costs, by the email they use for Equitrip."
        }
        let source = draft.sourceFileName ?? "Your document"
        return "\(source) is booked for \(draft.expectedTravellerCount) people but doesn't name them. Add them by email — we'll pull their name from their account."
    }

    // MARK: - Adding

    private var addField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "envelope")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .frame(width: 20)

                TextField("their@email.com", text: $entry)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.ink)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.emailAddress)
                    .submitLabel(.done)
                    .focused($entryFocused)
                    .onSubmit(add)
                    .onChange(of: entry) { lookupError = nil }

                Button(action: add) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 21))
                        .foregroundStyle(canAdd ? AppTheme.accent : AppTheme.inkTertiary.opacity(0.45))
                }
                .buttonStyle(.plain)
                .disabled(!canAdd || isResolving)
                .accessibilityLabel("Add this person")
            }
            .padding(.horizontal, 14)
            .frame(height: 54)
            .panelSurface(corner: 16)

            if let lookupError {
                Label(lookupError, systemImage: "exclamationmark.circle")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.danger)
                    .padding(.horizontal, 4)
            }
        }
    }

    /// Names the document did write down. Shown as a reminder of who to look
    /// up, never as people already added — the document knows what they're
    /// called, not how to reach them, and only the second one makes a
    /// traveller.
    private var documentNames: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.top, 1)

            Text("Your document mentions \(draft.namesFromDocument.joined(separator: ", ")). Add the addresses they use for Equitrip.")
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Roster

    private var roster: some View {
        VStack(spacing: 0) {
            youRow

            ForEach(rows) { row in
                Hairline(inset: 62)
                personRow(row)
            }

            ForEach(0..<max(0, expected - filled), id: \.self) { offset in
                Hairline(inset: 62)
                waitingRow(number: filled + offset + 1)
            }
        }
        .cardSurface(corner: 20)
    }

    private var youRow: some View {
        HStack(spacing: 13) {
            TravellerAvatar(traveller: .you, size: 38)

            VStack(alignment: .leading, spacing: 1) {
                Text(Traveller.you.name)
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text(CurrentUser.traveller.email ?? "You")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Text("You")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func personRow(_ row: Row) -> some View {
        HStack(spacing: 13) {
            switch row.state {
            case .resolving:
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 38, height: 38)
            case .member(let person), .invited(let person):
                TravellerAvatar(traveller: person, size: 38)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 21))
                    .foregroundStyle(AppTheme.danger)
                    .frame(width: 38, height: 38)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(primaryText(row))
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .contentTransition(.opacity)

                Text(secondaryText(row))
                    .font(.system(size: 12))
                    .foregroundStyle(statusTint(row))
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            if row.isInvited {
                ShareLink(item: inviteMessage(for: row.email)) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Share an invite with \(row.email)")
            }

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    rows.removeAll { $0.email == row.email }
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(AppTheme.inkTertiary.opacity(0.6))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(row.email)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func primaryText(_ row: Row) -> String {
        switch row.state {
        case .member(let person), .invited(let person): person.name
        case .resolving, .failed: row.email
        }
    }

    private func secondaryText(_ row: Row) -> String {
        switch row.state {
        case .resolving: "Looking them up…"
        case .member: row.email
        case .invited: "Not on Equitrip yet — they'll be invited"
        case .failed(let message): message
        }
    }

    private func statusTint(_ row: Row) -> Color {
        switch row.state {
        case .failed: AppTheme.danger
        case .invited: Palette.amber
        default: AppTheme.inkTertiary
        }
    }

    /// A slot the document counted but nobody has filled yet. Shown rather
    /// than left implicit, because "4 people" and three faces is a discrepancy
    /// somebody should notice before the costs are split three ways.
    private func waitingRow(number: Int) -> some View {
        HStack(spacing: 13) {
            Circle()
                .strokeBorder(
                    AppTheme.cardStroke.opacity(0.2),
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                )
                .frame(width: 38, height: 38)
                .overlay {
                    Text("\(number)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.inkTertiary)
                }

            Text("Waiting for an email address")
                .font(.system(size: 14.5))
                .foregroundStyle(AppTheme.inkTertiary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var note: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "sparkles")
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.top, 1)

            Text("Names come from people's own accounts, never from the document and never from us. Anyone not on Equitrip yet gets added as invited.")
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Continue

    private var continueBar: some View {
        VStack(spacing: 8) {
            if !everyoneAdded {
                Text("\(filled) of \(expected) added")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .contentTransition(.numericText())
            }

            Button(action: commit) {
                HStack(spacing: 7) {
                    Text(everyoneAdded ? "Continue" : "Continue with \(filled.pluralised("person", "people"))")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.accent)
            .disabled(isResolving)
        }
        .animation(.easeOut(duration: 0.2), value: everyoneAdded)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Work

    private func prepare() {
        appeared = true
        guard rows.isEmpty else { return }

        // Anybody already on the draft is already a row.
        //
        // This screen is now part of the hand-built route too, which means it
        // can be arrived at twice: add two friends, continue, then go back to
        // fix a date and come forward again. The rows are `@State` and die
        // with the screen, so a second visit started empty — and `commit`
        // writes the roster it can see, which would have been just you. The
        // two friends were dropped without a word.
        let existing = draft.travellers.filter {
            $0.id != Traveller.you.id && !($0.email ?? "").isEmpty
        }

        guard existing.isEmpty else {
            rows = existing.map { person in
                Row(
                    email: person.email ?? "",
                    state: person.isRegistered ? .member(person) : .invited(person)
                )
            }
            return
        }

        // Someone the document did name still has to become a real person, so
        // their address is what's missing, not their name.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { entryFocused = true }
    }

    /// Resolving on add rather than on every keystroke: a lookup per character
    /// is a request per character, and half of them are for addresses nobody
    /// finished typing.
    private func add() {
        guard canAdd else {
            if !entry.isEmpty { lookupError = "That doesn't look like an email address." }
            return
        }

        let email = TravellerDirectory.normalise(entry)
        entry = ""
        lookupError = nil
        rows.append(Row(email: email, state: .resolving))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task {
            isResolving = true
            defer { isResolving = false }

            do {
                let match = try await TravellerDirectory.claim(email)
                update(email) { row in
                    switch match {
                    case .registered(let person): row.state = .member(person)
                    case .invited(let person): row.state = .invited(person)
                    case .unknown: row.state = .failed("Couldn't add that address.")
                    }
                }
            } catch {
                let message = (error as? TravellerDirectory.DirectoryError)?.errorDescription
                    ?? AuthService.message(for: error)
                update(email) { $0.state = .failed(message) }
                lookupError = message
            }
        }
    }

    private func update(_ email: String, _ change: (inout Row) -> Void) {
        guard let index = rows.firstIndex(where: { $0.email == email }) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { change(&rows[index]) }
    }

    private func inviteMessage(for email: String) -> String {
        let name = draft.title.isEmpty ? "a trip" : draft.title
        return """
            I've added you to \(name) on Equitrip — it splits the costs so nobody \
            has to keep a spreadsheet. Sign up with \(email) and the trip will be \
            waiting for you.
            """
    }

    /// Only resolved people become travellers. A row that failed to look up is
    /// somebody we can't reach, and putting them on the trip anyway is exactly
    /// the invented-participant problem in a new shape.
    private func commit() {
        var travellers: [Traveller] = [.you]
        for row in rows {
            guard let person = row.traveller, person.id != Traveller.you.id else { continue }
            guard !travellers.contains(where: { $0.id == person.id }) else { continue }
            travellers.append(person)
        }

        draft.travellers = travellers

        // Every booking was provisionally everyone's; now that "everyone" has a
        // definite membership, the bookings have to agree with it.
        let everyone = Set(travellers.map(\.id))
        for index in draft.items.indices {
            draft.items[index].participantIDs = everyone
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onContinue()
    }
}
