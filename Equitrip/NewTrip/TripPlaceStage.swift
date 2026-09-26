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
/// trip itself — a tall postcard with the name on it — which is both the
/// confirmation that the right place was chosen and the thing every later
/// step edits.
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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Where to?")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text("A city, a region or a landmark — it names the trip and finds its photograph.")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .staggered(0, appeared)

                searchField
                    .staggered(1, appeared)

                if completer.results.isEmpty {
                    quiet
                        .staggered(2, appeared)
                } else {
                    results
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .animation(.spring(response: 0.36, dampingFraction: 0.88), value: completer.results.isEmpty)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(searchFocused ? AppTheme.accent : AppTheme.inkTertiary)

            TextField("Search cities and places", text: $completer.query)
                .font(.system(size: 17, weight: .medium))
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
                        .font(.system(size: 17))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 60)
        .cardSurface(corner: 20, shadow: searchFocused ? 16 : 8)
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(AppTheme.accent.opacity(searchFocused ? 0.55 : 0), lineWidth: 1.5)
        }
        .animation(.easeOut(duration: 0.18), value: searchFocused)
        .animation(.easeOut(duration: 0.18), value: completer.query.isEmpty)
    }

    private var results: some View {
        VStack(spacing: 0) {
            ForEach(Array(completer.results.enumerated()), id: \.element.id) { index, suggestion in
                Button {
                    choose(suggestion.formatted)
                } label: {
                    HStack(spacing: 13) {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(AppTheme.accent.opacity(0.1))
                            .frame(width: 38, height: 38)
                            .overlay {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppTheme.accent)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                                .font(.system(size: 15.5, weight: .semibold))
                                .foregroundStyle(AppTheme.ink)
                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle)
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(AppTheme.inkSecondary)
                                    .lineLimit(1)
                            }
                        }
                        .multilineTextAlignment(.leading)

                        Spacer(minLength: 6)

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())

                if index < completer.results.count - 1 { Hairline(inset: 65) }
            }
        }
        .cardSurface(corner: 22)
    }

    /// What's on screen before anything has been typed.
    ///
    /// Deliberately no list of somebody else's idea of popular destinations —
    /// that's an advertisement. The places this person has actually been are a
    /// shortcut, and they're drawn with their own photographs, because "Manali"
    /// as a word is a search result and Manali as the picture on last year's
    /// trip is a memory you recognise before you've read it.
    @ViewBuilder
    private var quiet: some View {
        if !revisitable.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Been before")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .padding(.leading, 2)
                    .padding(.top, 4)

                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(revisitable, id: \.id) { trip in
                            placeTile(trip)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }
        }
    }

    private func placeTile(_ trip: Trip) -> some View {
        Button {
            choose(trip.destination)
        } label: {
            DestinationImage(
                query: trip.destination,
                photo: trip.cover,
                fallbackSymbol: trip.symbol,
                fallbackTint: trip.tint
            )
            .frame(width: 138, height: 104)
            .overlay(alignment: .bottom) {
                LinearGradient(colors: [.clear, .black.opacity(0.62)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 64)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(trip.destination.components(separatedBy: ",")[0])
                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    Text(DateFormatter.cached("MMM yyyy").string(from: trip.startDate))
                        .font(.system(size: 11, weight: .medium))
                        .opacity(0.82)
                }
                .foregroundStyle(.white)
                .padding(10)
            }
            .clipShape(.rect(cornerRadius: 18, style: .continuous))
            .shadow(color: AppTheme.softShadow(.light), radius: 8, y: 3)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Go back to \(trip.destination)")
    }

    /// One trip per destination already on this account, newest first.
    private var revisitable: [Trip] {
        var seen = Set<String>()
        var trips: [Trip] = []

        for trip in store.trips.sorted(by: { $0.startDate > $1.startDate }) {
            let place = trip.destination.trimmingCharacters(in: .whitespaces)
            guard !place.isEmpty, seen.insert(place.lowercased()).inserted else { continue }
            trips.append(trip)
            if trips.count == 6 { break }
        }

        return trips
    }

    // MARK: - Chosen

    /// The trip as a postcard: tall enough to be the screen rather than a card
    /// floating at the top of an empty one.
    private var chosenBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(draft.destination.isEmpty ? "Name it, then." : "Here's your trip")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text(draft.destination.isEmpty
                         ? "No destination is fine — a trip only needs a name to exist."
                         : "Tap the name to rename it, the pin to go somewhere else.")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .staggered(0, appeared)

                TripCoverCard(
                    draft: $draft,
                    height: 450,
                    // Nobody has been asked about dates yet, so the default
                    // span isn't a fact about this trip.
                    showsDayCount: false,
                    onChangePhoto: { showImageSource = true },
                    onChangeDestination: { reopenSearch() },
                    isEditingTitle: $isEditingTitle
                )
                .staggered(1, appeared)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
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
                HStack(spacing: 6) {
                    Image(systemName: draft.destination.isEmpty ? "globe" : "arrow.uturn.backward")
                        .font(.system(size: 12, weight: .semibold))
                    Text(draft.destination.isEmpty ? "No fixed destination" : "Keep \(draft.destination)")
                        .font(.system(size: 14.5, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(AppTheme.inkSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassEffect(.regular.interactive(), in: .capsule)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        } else {
            StageActionBar(
                title: canContinue ? "Continue" : "Name your trip",
                symbol: canContinue ? "arrow.right" : "pencil",
                action: advance
            )
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
