//
//  TravellerPickerSheet.swift
//  Equitrip
//

import SwiftUI

/// Managing who's on the trip.
///
/// Pulled out of the forms into its own sheet because the list grows: a chip
/// wall inline is fine for three people and unusable for twelve, and adding
/// someone mid-trip is a thing that happens far more than once.
struct TravellerPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var travellers: [Traveller]
    /// Passed in when the caller is a trip whose organisers can be changed.
    var organiserIDs: Binding<Set<UUID>>?
    /// Everyone can see who's coming; only the organiser can change it.
    var isEditable: Bool = true
    /// The trip these people are on, when there is one.
    ///
    /// Optional because this sheet is also used by the new-trip flow, where
    /// there is no trip yet and nobody can have left one. When it's present,
    /// rows show who has gone and when, and taking somebody off routes through
    /// the departure flow instead of deleting them from the array.
    var trip: Trip?
    /// Opens the leave flow for one person. Nil means the caller doesn't
    /// support departures — the plain remove is used instead.
    var onLeave: ((Traveller) -> Void)?
    /// Asks somebody to join, rather than putting them on the trip.
    ///
    /// Nil in the new-trip flow, where there is no trip to be invited to yet
    /// and the people being picked are the ones creating it — those go
    /// straight onto the roster. On a trip that exists, this is the only way
    /// somebody gets added, because adding a person to a live ledger without
    /// asking them is how people end up owing money they never agreed to.
    var onInvite: ((Traveller) -> Void)?
    /// Withdraws an invitation nobody has answered.
    var onCancelInvite: ((Traveller) -> Void)?

    @State private var newEmail = ""
    @State private var isResolving = false
    @State private var addFailure: String?
    @FocusState private var addFocused: Bool

    private var canAdd: Bool {
        let email = TravellerDirectory.normalise(newEmail)
        return TravellerDirectory.isPlausible(email)
            && !travellers.contains { $0.email == email }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isEditable { addField }
                    list
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Travellers")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text(rosterCaption)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    /// By email, not by name.
    ///
    /// A name typed here made a person who existed only in this list: nobody
    /// could be notified, nobody's account ever matched them, and the same
    /// person added on two trips was two different debtors. The address is what
    /// makes them the same person twice, and it's what lets their own account
    /// supply their name.
    private var addField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "envelope")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .frame(width: 18)

                // Not a specimen address. "their@email.com" reads as a real
                // value somebody left in the field rather than as a prompt,
                // and iOS renders an address-shaped placeholder in a way that
                // looks tappable — so it said what to type at the cost of
                // looking like it had already been typed.
                TextField("Add a traveller by email", text: $newEmail)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.ink)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.emailAddress)
                    .focused($addFocused)
                    .submitLabel(.done)
                    .onSubmit(add)
                    .onChange(of: newEmail) { addFailure = nil }

                if isResolving {
                    ProgressView().controlSize(.small)
                } else {
                    Button(action: add) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(canAdd ? AppTheme.accent : AppTheme.inkTertiary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAdd)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .panelSurface(corner: 16)

            if let addFailure {
                Label(addFailure, systemImage: "exclamationmark.circle")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.danger)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(Array(travellers.enumerated()), id: \.element.id) { index, traveller in
                row(traveller)

                if index < travellers.count - 1 { Hairline(inset: 16) }
            }
        }
        .cardSurface(corner: 20)
    }

    private func row(_ traveller: Traveller) -> some View {
        let isYou = traveller.id == Traveller.you.id
        let isOrganiser = organiserIDs?.wrappedValue.contains(traveller.id) ?? false
        // Someone has to be able to edit; the last organiser can't step down.
        let isLastOrganiser = isOrganiser && (organiserIDs?.wrappedValue.count ?? 0) <= 1
        let hasLeft = trip?.hasLeft(traveller.id) ?? false
        let leaving = trip?.pendingDeparture(for: traveller.id) != nil
        let isInvited = trip?.isInvited(traveller.id) ?? false

        return HStack(spacing: 12) {
            TravellerAvatar(traveller: traveller, size: 36, isDimmed: hasLeft || isInvited)

            VStack(alignment: .leading, spacing: 1) {
                Text(isYou ? "\(traveller.name) (you)" : traveller.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(hasLeft || isInvited ? AppTheme.inkSecondary : AppTheme.ink)

                if let email = traveller.email, !traveller.isRegistered {
                    Text("Invited · \(email)")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Palette.amber)
                        .lineLimit(1)
                } else if let email = traveller.email, !isYou {
                    Text(email)
                        .font(.system(size: 11.5))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .lineLimit(1)
                }

                // The one line that answers "were they here for this?".
                // It replaces the organiser badge rather than stacking under
                // it: somebody who has gone home is no longer organising
                // anything, and two badges on one row is a row nobody reads.
                if isInvited {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text("Invited · not on the trip yet")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.accent)
                } else if hasLeft, let presence = trip?.presenceLabel(traveller.id) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.to.line")
                            .font(.system(size: 8, weight: .bold))
                        Text(presence)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.inkTertiary)
                } else if leaving {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text("Asked to leave")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Palette.amber)
                } else if isOrganiser {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text("Organiser")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.accent)
                }
            }

            Spacer(minLength: 6)

            Menu {
                if isEditable, let organiserIDs {
                    if isOrganiser {
                        Button {
                            withAnimation { _ = organiserIDs.wrappedValue.remove(traveller.id) }
                        } label: {
                            Label("Remove as organiser", systemImage: "star.slash")
                        }
                        .disabled(isLastOrganiser)
                    } else {
                        Button {
                            withAnimation { _ = organiserIDs.wrappedValue.insert(traveller.id) }
                        } label: {
                            Label("Make organiser", systemImage: "star")
                        }
                    }
                }

                // Two very different acts wearing one label until now.
                //
                // Before a trip starts, nobody has paid for anything and there
                // is no history to preserve, so taking a name off the list
                // really is just that. Once it's running, the same tap would
                // silently re-divide every booking they were on — including
                // ones already settled — so it routes through the departure
                // flow instead, which shows the arithmetic and asks.
                if let onLeave, !hasLeft, !leaving, !isInvited, isEditable || isYou {
                    Button(role: isYou ? .destructive : nil) {
                        onLeave(traveller)
                    } label: {
                        Label(
                            isYou ? "Leave this trip" : "Take \(traveller.name) off the trip",
                            systemImage: isYou ? "rectangle.portrait.and.arrow.right" : "person.badge.minus"
                        )
                    }
                }

                if let onCancelInvite, isInvited, isEditable {
                    Button(role: .destructive) {
                        onCancelInvite(traveller)
                    } label: {
                        Label("Withdraw invitation", systemImage: "envelope.badge.shield.half.filled")
                    }
                }

                if onLeave == nil, onInvite == nil, isEditable, !isYou, !isOrganiser {
                    Button(role: .destructive) {
                        withAnimation { travellers.removeAll { $0.id == traveller.id } }
                    } label: {
                        Label("Remove from trip", systemImage: "person.badge.minus")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 17))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .opacity(canAct(isYou: isYou, hasLeft: hasLeft) ? 1 : 0)
            }
            .disabled(!canAct(isYou: isYou, hasLeft: hasLeft))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// Whether this row's menu has anything in it.
    ///
    /// Leaving is the one action that isn't the organiser's to gate: a
    /// traveller who is not organising still gets to go home, and a sheet that
    /// hid the control from them would leave them asking someone else to
    /// remove them — which is the destructive path this whole flow replaces.
    private func canAct(isYou: Bool, hasLeft: Bool) -> Bool {
        if hasLeft { return false }
        if isYou, onLeave != nil { return true }
        return isEditable
    }

    /// "3 on this trip · 1 invited". The count people read as the group size
    /// should be the group, not the group plus everyone who has been asked.
    private var rosterCaption: String {
        let pending = trip?.pendingInviteCount ?? 0
        let joined = travellers.count - pending
        let base = "\(joined) on this trip"
        return pending == 0 ? base : "\(base) · \(pending) invited"
    }

    private func add() {
        guard canAdd else {
            if !newEmail.isEmpty { addFailure = "That doesn't look like an email address." }
            return
        }

        let email = TravellerDirectory.normalise(newEmail)
        newEmail = ""
        addFailure = nil

        Task {
            isResolving = true
            defer { isResolving = false }

            do {
                guard let person = try await TravellerDirectory.claim(email).traveller else {
                    addFailure = "Couldn't add that address."
                    return
                }
                guard !travellers.contains(where: { $0.id == person.id }) else {
                    addFailure = "\(person.name) is already on this trip."
                    return
                }
                if let onInvite {
                    onInvite(person)
                } else {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.8)) {
                        travellers.append(person)
                    }
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                addFocused = true
            } catch {
                addFailure = (error as? TravellerDirectory.DirectoryError)?.errorDescription
                    ?? AuthService.message(for: error)
            }
        }
    }
}

// MARK: - Row affordance

/// The collapsed form of the above: a single row showing who's coming, which
/// opens the sheet. Replaces the inline chip wall on every form that had one.
struct TravellerSummaryRow: View {
    let travellers: [Traveller]
    var organisers: [Traveller] = []
    let action: () -> Void

    private var organiserLine: String {
        let names = organisers.map(\.name)
        switch names.count {
        case 0: return ""
        case 1: return "\(names[0]) is organising"
        case 2: return "\(names[0]) and \(names[1]) are organising"
        default: return "\(names[0]) and \(names.count - 1) others are organising"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if travellers.isEmpty {
                    SymbolBadge(symbol: "person.2", tint: AppTheme.accent, size: 34)
                } else {
                    AvatarStack(travellers: travellers, size: 32, max: 4)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(travellers.isEmpty ? "Add travellers" : travellers.count.pluralised("traveller"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.ink)

                    if !organisers.isEmpty {
                        Text(organiserLine)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.inkTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .panelSurface(corner: 18)
    }
}
