//
//  BookingReaderSettingsSheet.swift
//  Equitrip
//

import SwiftUI
import FoundationModels

/// Choosing the model that reads an imported booking PDF: Apple Intelligence
/// on this device, or one of this account's Nugen domain-aligned models.
///
/// The Nugen list is fetched live from the `nugen-reader` function rather than
/// hard-coded, so a model deployed (or retrained and redeployed) in the Nugen
/// dashboard shows up here without a new build. The sheet says plainly that a
/// Nugen model reads in the cloud: the settings screen is where the Gmail
/// promise ("mail never leaves this phone") is made, and this choice mustn't
/// look like it weakens it — so it names what it covers, and what it doesn't.
struct BookingReaderSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: BookingReader

    private enum Load {
        case loading
        case loaded([NugenService.Model])
        case failed(String)
    }

    @State private var load = Load.loading

    private var appleIsAvailable: Bool { SystemLanguageModel.default.isAvailable }

    var body: some View {
        SettingsSheetScaffold(
            title: "Booking reader",
            caption: "The model that turns a booking PDF into your trip's bookings. Equi and Gmail always use Apple Intelligence on this device."
        ) {
            option(
                .appleIntelligence,
                mark: "FoundationModelsMark",
                title: "Apple Intelligence",
                detail: appleIsAvailable
                    ? "On this device · nothing is uploaded"
                    : "Not available here · pattern matching instead"
            )
            .cardSurface(corner: 22)

            header("Nugen aligned models")

            nugenModels
                .cardSurface(corner: 22)

            Text("A Nugen model reads each day of the booking's text on Nugen's servers, sent through Equitrip's own server. Times and amounts are still copied from the document on this phone, never from the model.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.inkTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 6)
        }
        .task { await refresh() }
    }

    // MARK: - Nugen

    @ViewBuilder
    private var nugenModels: some View {
        switch load {
        case .loading:
            HStack(spacing: 10) {
                ProgressView()
                Text("Finding your models…")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.inkSecondary)
                Spacer(minLength: 0)
            }
            .padding(16)

        case .loaded(let models) where models.isEmpty && selection.nugenModelID == nil:
            message(
                "No deployed model yet",
                detail: "Deploy an aligned model in the Nugen dashboard and it appears here."
            )

        case .loaded(let models):
            let listed = models.map { BookingReader.nugen(id: $0.id, name: $0.name) }
            // The chosen model stays visible even when it's been undeployed,
            // so the list never disagrees with the row that opened it.
            let rows = listed.contains(selection) || selection.nugenModelID == nil ? listed : [selection] + listed
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element) { index, reader in
                    let model = models.first { $0.id == reader.nugenModelID }
                    option(
                        reader,
                        mark: "NugenMark",
                        title: reader.label,
                        detail: model.map {
                            $0.base.isEmpty ? "Reads in the cloud" : "Aligned from \($0.base) · reads in the cloud"
                        } ?? "Not deployed right now · falls back to pattern matching"
                    )
                    if index < rows.count - 1 { Hairline(inset: 16) }
                }
            }

        case .failed(let reason):
            VStack(spacing: 0) {
                if case .nugen = selection {
                    option(selection, mark: "NugenMark", title: selection.label, detail: "Chosen · Nugen can't be reached right now")
                    Hairline(inset: 16)
                }
                Button {
                    Task { await refresh() }
                } label: {
                    message("Couldn't reach Nugen", detail: "\(reason) Tap to try again.")
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    private func refresh() async {
        load = .loading
        do {
            load = .loaded(try await NugenService.models())
        } catch {
            load = .failed(NugenService.reason(for: error))
        }
    }

    // MARK: - Rows

    private func option(_ reader: BookingReader, mark: String, title: String, detail: String) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selection = reader
            dismiss()
        } label: {
            HStack(spacing: 12) {
                // The model's own logo, not an SF Symbol: Apple's and Nugen's
                // marks are what tells the two readers apart at a glance.
                // Apple's mark is a full-bleed colour tile and Nugen's sits on
                // white, so at equal sizes Apple's reads larger — it's inset.
                let side: CGFloat = reader == .appleIntelligence ? 28 : 32
                Image(mark)
                    .resizable()
                    .scaledToFit()
                    .frame(width: side, height: side)
                    .clipShape(.rect(cornerRadius: side / 4, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: side / 4, style: .continuous)
                            .strokeBorder(AppTheme.ink.opacity(0.08), lineWidth: 0.5)
                    }
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)

                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.inkTertiary)
                }

                Spacer(minLength: 6)

                Image(systemName: selection == reader ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19))
                    .foregroundStyle(selection == reader ? AppTheme.accent : AppTheme.inkTertiary.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func message(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 14.5, weight: .medium))
                .foregroundStyle(AppTheme.ink)
            Text(detail)
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .contentShape(.rect)
    }

    private func header(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(0.9)
            .foregroundStyle(AppTheme.inkTertiary)
            .padding(.leading, 6)
            .padding(.top, 6)
    }
}
