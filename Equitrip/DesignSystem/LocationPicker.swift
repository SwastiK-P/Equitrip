//
//  LocationPicker.swift
//  Equitrip
//

import SwiftUI
import MapKit

/// Live place suggestions from Apple Maps.
///
/// A trip's destination has to be a real place, not free text — the photo
/// lookup searches on it and every screen shows it, so "goa" and "Goa, India"
/// shouldn't be two different trips.
@MainActor
@Observable
final class LocationCompleter: NSObject, MKLocalSearchCompleterDelegate {
    var query: String = "" {
        didSet {
            guard query != oldValue else { return }
            let trimmed = query.trimmingCharacters(in: .whitespaces)
            // Below two characters Maps returns noise, and an empty fragment
            // makes the completer hold on to the previous results.
            if trimmed.count < 2 {
                results = []
                completer.cancel()
            } else {
                completer.queryFragment = trimmed
            }
        }
    }

    private(set) var results: [Suggestion] = []

    /// `MKLocalSearchCompletion` isn't `Identifiable` and is replaced wholesale
    /// on every keystroke, so results are mirrored into a stable value type.
    struct Suggestion: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let subtitle: String

        /// What gets stored on the trip: "Goa, India" rather than either half.
        var formatted: String {
            subtitle.isEmpty ? title : "\(title), \(subtitle)"
        }
    }

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results.prefix(8).map {
            Suggestion(title: $0.title, subtitle: $0.subtitle)
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}

// MARK: - Sheet

/// Search-and-pick for a trip destination.
struct LocationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var completer = LocationCompleter()
    @FocusState private var searchFocused: Bool

    var initial: String = ""
    var onPick: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            searchField
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            if completer.results.isEmpty {
                emptyState
            } else {
                results
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .onAppear {
            completer.query = initial
            searchFocused = true
        }
    }

    private var header: some View {
        HStack {
            Text("Destination")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)

            TextField("Search cities and places", text: $completer.query)
                .font(.system(size: 16))
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
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .panelSurface(corner: 16)
    }

    private var results: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(completer.results.enumerated()), id: \.element.id) { index, suggestion in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onPick(suggestion.formatted)
                        dismiss()
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
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 20)

            Image(systemName: "map")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(AppTheme.inkTertiary)

            Text(completer.query.count < 2 ? "Where are you going?" : "No places match that")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.inkSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
