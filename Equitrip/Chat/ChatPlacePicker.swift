//
//  ChatPlacePicker.swift
//  Equitrip
//

import SwiftUI
import MapKit

/// Finding a place to send: "meet here", with a pin people can open in Maps.
///
/// Uses the same Apple Maps completer as the trip destination field, then
/// resolves the pick to coordinates — the card needs a point to draw, and a
/// name alone sends two people to two different "Anjuna Beach Café"s.
struct ChatPlacePicker: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    var onPick: (ChatAttachment) -> Void

    @State private var completer = LocationCompleter()
    @State private var resolving: LocationCompleter.Suggestion?
    @State private var failed = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ChatSheetHeader(title: "Share a place")

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)

                TextField("Search restaurants, beaches, addresses", text: $completer.query)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.ink)
                    .autocorrectionDisabled()
                    .focused($searchFocused)
                    .submitLabel(.search)

                if !completer.query.isEmpty {
                    Button { completer.query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .panelSurface(corner: 16)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            if failed {
                Text("Couldn't find that on the map. Try another result.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.danger)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if completer.results.isEmpty {
                        shortcuts
                    } else {
                        results
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .onAppear { searchFocused = true }
    }

    private var results: some View {
        VStack(spacing: 0) {
            ForEach(Array(completer.results.enumerated()), id: \.element.id) { index, suggestion in
                Button { resolve(suggestion) } label: {
                    HStack(spacing: 12) {
                        SymbolBadge(symbol: "mappin", tint: AppTheme.danger, size: 32)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(suggestion.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppTheme.ink)
                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle)
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(AppTheme.inkSecondary)
                            }
                        }
                        .multilineTextAlignment(.leading)

                        Spacer(minLength: 6)

                        if resolving?.id == suggestion.id {
                            ProgressView().tint(AppTheme.inkTertiary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(resolving != nil)

                if index < completer.results.count - 1 { Hairline(inset: 16) }
            }
        }
        .cardSurface(corner: 20)
    }

    /// Places this trip already involves, one tap from a search.
    @ViewBuilder
    private var shortcuts: some View {
        let names = shortcutNames
        if !names.isEmpty {
            Text("On this trip")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(AppTheme.inkSecondary)
                .padding(.horizontal, 4)

            FlowLayout(spacing: 8) {
                ForEach(names, id: \.self) { name in
                    Button { completer.query = name } label: {
                        Label(name, systemImage: "magnifyingglass")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.ink)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(AppTheme.card, in: .capsule)
                            .overlay { Capsule().strokeBorder(AppTheme.cardStroke.opacity(0.08)) }
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    private var shortcutNames: [String] {
        let vendors = trip.items
            .filter { $0.kind != .flight && $0.kind != .train }
            .compactMap(\.vendorName)
        let all = [trip.destination] + vendors
        return Array(NSOrderedSet(array: all).array.compactMap { $0 as? String }.filter { !$0.isEmpty }.prefix(8))
    }

    private func resolve(_ suggestion: LocationCompleter.Suggestion) {
        resolving = suggestion
        failed = false

        Task {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = suggestion.formatted
            request.resultTypes = [.address, .pointOfInterest]

            guard let item = try? await MKLocalSearch(request: request).start().mapItems.first else {
                resolving = nil
                failed = true
                return
            }

            let coordinate = item.location.coordinate
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onPick(.place(.init(
                name: suggestion.title,
                subtitle: suggestion.subtitle,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )))
            resolving = nil
            dismiss()
        }
    }
}
