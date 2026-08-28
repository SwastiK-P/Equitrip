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
                Text("\(travellers.count) on this trip")
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

                TextField("their@email.com", text: $newEmail)
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

        return HStack(spacing: 12) {
            MemojiAvatar(traveller: traveller, size: 36)

            VStack(alignment: .leading, spacing: 1) {
                Text(isYou ? "\(traveller.name) (you)" : traveller.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.ink)

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

                if isOrganiser {
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

                // Removing the organiser would leave nobody able to edit, and
                // removing yourself leaves a trip you can't settle.
                if isEditable, !isYou, !isOrganiser {
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
                    .opacity(isEditable ? 1 : 0)
            }
            .disabled(!isEditable)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
                withAnimation(.spring(response: 0.34, dampingFraction: 0.8)) {
                    travellers.append(person)
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
