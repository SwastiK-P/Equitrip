//
//  ParticipantPickerSheet.swift
//  Equitrip
//

import SwiftUI

/// Who's on one booking.
///
/// Was a wall of tappable chips sitting inline under the form, which had two
/// problems: a chip's selected state is carried by a tint and a desaturated
/// avatar, which is not a thing anyone reads as "on" or "off", and eight
/// people wrapped onto four rows that pushed the rest of the form off screen.
/// A row that says who's on it, opening a list with real checkmarks, is one
/// line either way and unambiguous about what's selected.
///
/// Read-only when `selection` is nil — the same list, without the taps, for
/// everybody who can see a booking but can't edit it.
struct ParticipantPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let travellers: [Traveller]
    /// What each person would owe, shown against their name. Nil when the
    /// booking is free or the caller has no split to apply.
    var shareEach: Double?
    var currencyCode: String = "INR"
    var selection: Binding<Set<UUID>>?
    /// Pick exactly one, for the split modes that name a single person.
    ///
    /// Changes what an empty set means, which is the subtle part: everywhere
    /// else in the app "nobody selected" is shorthand for "everybody", because
    /// a booking with no names on it is a whole-group cost. Under
    /// single-selection that reading is nonsense — "one person, unspecified,
    /// owes all of it" isn't a state worth being able to express — so empty
    /// means empty and the sheet says so.
    var singleSelection: Bool = false

    private var isEditable: Bool { selection != nil }

    private func isOn(_ traveller: Traveller) -> Bool {
        guard let selection else { return true }
        if singleSelection { return selection.wrappedValue.contains(traveller.id) }
        return selection.wrappedValue.isEmpty || selection.wrappedValue.contains(traveller.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(travellers.enumerated()), id: \.element.id) { index, traveller in
                        row(traveller)

                        if index < travellers.count - 1 { Hairline(inset: 16) }
                    }
                }
                .cardSurface(corner: 20)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents([.medium, .large])
        .presentationBackground { CanvasBackground() }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(singleSelection ? "Who's carrying this" : "Who's on this")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(caption)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 8)

            if let selection, !singleSelection {
                Button(allSelected ? "Clear" : "Everyone") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeOut(duration: 0.2)) {
                        selection.wrappedValue = allSelected ? [] : Set(travellers.map(\.id))
                    }
                }
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .buttonStyle(.plain)
            }

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    private var caption: String {
        let count = travellers.filter(isOn).count
        if singleSelection {
            guard let chosen = travellers.first(where: isOn) else { return "Pick one person" }
            return "\(chosen.name) owes the full amount"
        }
        guard let shareEach, shareEach > 0 else { return "\(count) of \(travellers.count)" }
        return "\(Money.format(shareEach, code: currencyCode)) each"
    }

    private var allSelected: Bool {
        guard let selection else { return true }
        return !travellers.isEmpty && selection.wrappedValue.count == travellers.count
    }

    private func row(_ traveller: Traveller) -> some View {
        let on = isOn(traveller)

        return Button {
            guard let selection else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                guard !singleSelection else {
                    // Radio behaviour, and no way back to nobody: tapping the
                    // one that's already on is a mis-tap, not a deselection.
                    selection.wrappedValue = [traveller.id]
                    return
                }

                // An empty set has been standing in for "everyone", so the
                // first tap has to make that implicit set explicit before it
                // can take somebody out of it — otherwise deselecting one
                // person reads as selecting them.
                var picked = selection.wrappedValue.isEmpty
                    ? Set(travellers.map(\.id))
                    : selection.wrappedValue

                if picked.contains(traveller.id) {
                    picked.remove(traveller.id)
                } else {
                    picked.insert(traveller.id)
                }
                selection.wrappedValue = picked
            }
        } label: {
            HStack(spacing: 12) {
                TravellerAvatar(traveller: traveller, size: 36)
                    .saturation(on ? 1 : 0.15)

                VStack(alignment: .leading, spacing: 1) {
                    Text(traveller.id == Traveller.you.id ? "\(traveller.name) (you)" : traveller.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(on ? AppTheme.ink : AppTheme.inkTertiary)

                    if on, let shareEach, shareEach > 0, !singleSelection {
                        Text("owes \(Money.format(shareEach, code: currencyCode))")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                }

                Spacer(minLength: 6)

                Image(systemName: on ? (singleSelection ? "largecircle.fill.circle" : "checkmark.circle.fill") : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(on ? AppTheme.accent : AppTheme.inkTertiary.opacity(0.4))
                    .symbolEffect(.bounce, value: on)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        // Read-only callers get the same list without the taps.
        .disabled(!isEditable)
    }
}

// MARK: - Row affordance

/// The collapsed form: one row of faces that opens the sheet. Replaces the
/// inline chip wall on the booking editor and the booking detail sheet.
struct ParticipantSummaryRow: View {
    let travellers: [Traveller]
    /// What it works out to each, when there's a cost to divide.
    var shareEach: Double?
    var currencyCode: String = "INR"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if travellers.isEmpty {
                    SymbolBadge(symbol: "person.2", tint: AppTheme.accent, size: 34)
                } else {
                    AvatarStack(travellers: travellers, size: 32, max: 5)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(travellers.isEmpty ? "Nobody yet" : travellers.count.pluralised("person", "people"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.ink)

                    if let shareEach, shareEach > 0 {
                        Text("\(Money.format(shareEach, code: currencyCode)) each")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.inkTertiary)
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
