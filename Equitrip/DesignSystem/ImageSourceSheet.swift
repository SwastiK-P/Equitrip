//
//  ImageSourceSheet.swift
//  Equitrip
//

import SwiftUI
import PhotosUI

/// Where a booking's photo comes from: searched on Unsplash, or picked from
/// the library. Two very different flows — one is a search-and-tap, the
/// other hands off to the system picker — so this starts as a choice between
/// them rather than trying to cram both into one screen.
struct ImageSourceSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// The default search term — usually the booking's title or vendor.
    var suggestedQuery: String
    /// Called with a photo that still needs `CoverStore.persist(_:for:)` run
    /// on it (the Unsplash result), or `nil` alongside `data` for a picked
    /// library image that needs `CoverStore.persist(imageData:for:)` instead.
    var onPickUnsplash: (TripPhoto) -> Void
    var onPickLibrary: (Data) -> Void

    @State private var stage: Stage = .choose
    @State private var libraryItem: PhotosPickerItem?

    private enum Stage { case choose, search }

    var body: some View {
        Group {
            switch stage {
            case .choose: choices
            case .search:
                UnsplashSearchView(initialQuery: suggestedQuery) { photo in
                    onPickUnsplash(photo)
                    dismiss()
                }
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .onChange(of: libraryItem) { _, item in
            guard let item else { return }
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self) else { return }
                onPickLibrary(data)
                dismiss()
            }
        }
    }

    private var choices: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add a photo")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Spacer(minLength: 8)

                CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                    .accessibilityLabel("Close")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 18)

            VStack(spacing: 10) {
                choiceRow(
                    symbol: "sparkle.magnifyingglass",
                    tint: AppTheme.accent,
                    title: "Search Unsplash",
                    subtitle: "Find a photo of the place or the thing"
                ) {
                    stage = .search
                }

                PhotosPicker(selection: $libraryItem, matching: .images, photoLibrary: .shared()) {
                    choiceLabel(
                        symbol: "photo.on.rectangle.angled",
                        tint: Palette.amber,
                        title: "Choose from Photos",
                        subtitle: "Use one you already have"
                    )
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
    }

    private func choiceRow(symbol: String, tint: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            choiceLabel(symbol: symbol, tint: tint, title: title, subtitle: subtitle)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func choiceLabel(symbol: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            SymbolBadge(symbol: symbol, tint: tint, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .contentShape(.rect)
        .panelSurface(corner: 18)
    }
}

/// A search field over a grid of Unsplash results. Picking a tile hands the
/// chosen `TripPhoto` straight back — persisting it to storage is the
/// caller's job, same as the trip cover flow.
private struct UnsplashSearchView: View {
    let initialQuery: String
    var onPick: (TripPhoto) -> Void

    @State private var query: String
    @State private var results: [TripPhoto] = []
    @State private var isSearching = false
    @State private var searched = false
    @State private var searchTask: Task<Void, Never>?

    init(initialQuery: String, onPick: @escaping (TripPhoto) -> Void) {
        self.initialQuery = initialQuery
        self.onPick = onPick
        _query = State(initialValue: initialQuery)
    }

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)

            ScrollView {
                if isSearching {
                    LoadingState(message: "Searching Unsplash…")
                        .padding(.top, 60)
                } else if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    // The booking's own title seeds the field, but a brand new
                    // one has no title yet — nothing to search for, so say so
                    // instead of sitting there blank.
                    promptState
                } else if searched, results.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(results, id: \.url) { photo in
                            tile(photo)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .scrollIndicators(.hidden)
        }
        .task { await runSearch() }
        .onDisappear { searchTask?.cancel() }
    }

    private var promptState: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
            Text("Search for a place, a vendor, anything")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.inkSecondary)
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)

            TextField("Search photos", text: $query)
                .font(.system(size: 16))
                .submitLabel(.search)
                .onSubmit { debouncedSearch(delay: 0) }
                .onChange(of: query) { _, _ in debouncedSearch(delay: 0.4) }

            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                    searched = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .panelSurface(corner: 16)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
            Text("No photos found for \"\(query)\"")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.inkSecondary)
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity)
    }

    private func tile(_ photo: TripPhoto) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onPick(photo)
        } label: {
            // Square, tied to the column's own width rather than a fixed
            // point height — a `.frame(height:)` alone left each tile's
            // *width* to whatever the image's intrinsic size implied before
            // the fill frame resolved, so a tile could flash at its native
            // aspect ratio (a tall sliver, or a doubled-up row) for a beat.
            // Locking width and height together to the grid cell removes
            // that degree of freedom entirely.
            GeometryReader { geo in
                AsyncImage(url: photo.thumbURL ?? photo.url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                    default:
                        AppTheme.card
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipShape(.rect(cornerRadius: 14, style: .continuous))
                .overlay(alignment: .bottomLeading) {
                    Text(photo.photographer)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                        .padding(6)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func debouncedSearch(delay: Double) {
        searchTask?.cancel()
        searchTask = Task {
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { return }
            }
            await runSearch()
        }
    }

    private func runSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            // Cleared back to empty — drop whatever was showing rather than
            // leaving stale results up under an empty field.
            results = []
            searched = false
            isSearching = false
            return
        }

        isSearching = true
        let found = await PhotoService.shared.search(trimmed)
        guard !Task.isCancelled else { return }
        results = found
        searched = true
        isSearching = false
    }
}
