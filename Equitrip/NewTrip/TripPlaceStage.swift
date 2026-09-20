//
//  TripPlaceStage.swift
//  Equitrip
//

import SwiftUI

/// Step one of building a trip by hand: where.
///
/// It's the first question because it answers three others for free — the
/// trip's name, its photograph and its glyph all fall out of a place, and a
/// screen that opens with an empty `Trip name` box makes you invent one before
/// it will let you think about anything else.
///
/// The screen has two states and no scrolling form between them. Searching, it
/// is a field and a list of places. Once somewhere is picked it becomes the
/// trip itself — cover, name, destination — which is both the confirmation
/// that the right place was chosen and the thing every later step edits.
struct TripPlaceStage: View {
    @Environment(\.tripStore) private var store

    @Binding var draft: TripDraft
    var onContinue: () -> Void

    @State private var completer = LocationCompleter()
    @State private var searching = true
    @State private var isEditingTitle = false
    @State private var showImageSource = false
    @State private var appeared = false
    @FocusState private var searchFocused: Bool

    private var canContinue: Bool { draft.isValid }

    var body: some View {
        Group {
            if searching {
                searchBody
            } else {
                chosenBody
            }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .animation(.spring(response: 0.42, dampingFraction: 0.88), value: searching)
        .onAppear(perform: prepare)
        .sheet(isPresented: $showImageSource) {
            ImageSourceSheet(
                suggestedQuery: draft.destination.isEmpty ? draft.title : draft.destination,
                onPickUnsplash: { photo in
                    let tripID = draft.id
                    Task {
                        let stored = await CoverStore.shared.persist(photo, for: tripID)
                        draft.cover = stored
                    }
                },
                onPickLibrary: { data in
                    let tripID = draft.id
                    Task {
                        if let stored = await CoverStore.shared.persist(imageData: data, for: tripID) {
                            draft.cover = stored
                        }
                    }
                }
            )
        }
    }

    // MARK: - Searching

    private var searchBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Where are you")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text("going?")
                    .font(AppTheme.display(32))
                    .foregroundStyle(AppTheme.accent)
            }
            .staggered(0, appeared)

            searchField
                .staggered(1, appeared)

            if completer.results.isEmpty {
                quiet
                    .staggered(2, appeared)
            } else {
                results
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)

            TextField("Search cities and places", text: $completer.query)
                .font(.system(size: 16.5))
                .foregroundStyle(AppTheme.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($searchFocused)
                .submitLabel(.search)

            if !completer.query.isEmpty {
                Button {
                    completer.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear")
            }
        }
        .padding(.horizontal, 15)
        .frame(height: 54)
        .panelSurface(corner: 17)
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(AppTheme.accent, lineWidth: searchFocused ? 1.6 : 0)
        }
        .animation(.easeOut(duration: 0.18), value: searchFocused)
    }

    private var results: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(completer.results.enumerated()), id: \.element.id) { index, suggestion in
                    Button {
                        choose(suggestion.formatted)
                    } label: {
                        HStack(spacing: 12) {
                            SymbolBadge(symbol: "mappin", tint: AppTheme.accent, size: 32)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(suggestion.title)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(AppTheme.ink)
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(.system(size: 12.5))
                                        .foregroundStyle(AppTheme.inkSecondary)
                                        .lineLimit(2)
                                }
                            }
                            .multilineTextAlignment(.leading)

                            Spacer(minLength: 6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(.rect)
                    }
                    .buttonStyle(PressableButtonStyle())

                    if index < completer.results.count - 1 { Hairline(inset: 16) }
                }
            }
            .cardSurface(corner: 20)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    /// What's on screen before anything has been typed.
    ///
    /// Deliberately almost nothing. A list of somebody else's idea of popular
    /// destinations is an advertisement; the places this person has actually
    /// been are a shortcut, and when there aren't any the honest answer is an
    /// empty screen with the cursor already in the field.
    @ViewBuilder
    private var quiet: some View {
        if revisitable.isEmpty {
            Text("Pick a city, a region or a landmark — it names the trip and finds its photograph.")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.inkTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 2)
                .padding(.top, 2)
        } else {
            VStack(alignment: .leading, spacing: 9) {
                Text("BEEN BEFORE")
                    .font(.system(size: 10.5, weight: .bold))
                    .tracking(0.9)
                    .foregroundStyle(AppTheme.inkTertiary)
                    .padding(.leading, 2)
                    .padding(.top, 4)

                FlowLayout(spacing: 8, rowSpacing: 8) {
                    ForEach(revisitable, id: \.self) { place in
                        Button {
                            choose(place)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppTheme.inkTertiary)
                                Text(place)
                                    .font(.system(size: 13.5, weight: .medium))
                                    .foregroundStyle(AppTheme.ink)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .panelSurface(corner: 16)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }
        }
    }

    /// Destinations already on this account's trips, newest first.
    private var revisitable: [String] {
        var seen = Set<String>()
        var places: [String] = []

        for trip in store.trips.sorted(by: { $0.startDate > $1.startDate }) {
            let place = trip.destination.trimmingCharacters(in: .whitespaces)
            guard !place.isEmpty, seen.insert(place.lowercased()).inserted else { continue }
            places.append(place)
            if places.count == 4 { break }
        }

        return places
    }

    // MARK: - Chosen

    private var chosenBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(draft.destination.isEmpty ? "Name it, then." : "Here's your trip")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text(draft.destination.isEmpty
                         ? "No destination is fine — a trip only needs a name to exist. You can add a place later."
                         : "Tap the name to change it, or the pin to go somewhere else.")
                        .font(.system(size: 14.5))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                TripCoverCard(
                    draft: $draft,
                    height: 216,
                    // Nobody has been asked about dates yet, so the default
                    // span isn't a fact about this trip.
                    showsDayCount: false,
                    onChangePhoto: { showImageSource = true },
                    onChangeDestination: { reopenSearch() },
                    isEditingTitle: $isEditingTitle
                )

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Bottom

    @ViewBuilder
    private var bottomBar: some View {
        if searching {
            Button(action: leaveSearch) {
                Text(draft.destination.isEmpty ? "No fixed destination" : "Keep \(draft.destination)")
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 4)
        } else {
            Button(action: advance) {
                HStack(spacing: 7) {
                    Text(canContinue ? "Continue" : "Name your trip")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: canContinue ? "arrow.right" : "pencil")
                        .font(.system(size: 13, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.accent)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Work

    private func prepare() {
        withAnimation { appeared = true }

        // Coming back from a later step, the place is already settled and the
        // card is what should be showing — not the search that produced it.
        searching = draft.destination.isEmpty && draft.title.isEmpty
        guard searching else { return }

        completer.query = draft.destination
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { searchFocused = true }
    }

    private func choose(_ place: String) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        draft.destination = place
        // A trip with no name yet takes the destination's own — one less empty
        // field between here and a real trip.
        if draft.title.trimmingCharacters(in: .whitespaces).isEmpty {
            draft.title = place.components(separatedBy: ",")[0]
        }
        // The old cover, if any, was fetched for the old place.
        draft.cover = nil

        searchFocused = false
        searching = false
    }

    private func leaveSearch() {
        searchFocused = false
        searching = false
    }

    private func reopenSearch() {
        completer.query = draft.destination
        searching = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { searchFocused = true }
    }

    /// Never a dead button: with no name it says so and opens the field, which
    /// is one tap rather than a hunt for whatever is missing.
    private func advance() {
        guard canContinue else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            isEditingTitle = true
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onContinue()
    }
}
