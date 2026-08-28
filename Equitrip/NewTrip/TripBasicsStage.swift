//
//  TripBasicsStage.swift
//  Equitrip
//

import SwiftUI

/// The manual route: the handful of facts a trip can't exist without.
///
/// Bookings are deliberately *not* here. Asking for flights before the trip
/// exists is the thing that makes people abandon this kind of form; they get
/// added on the review screen and afterwards, as they're booked.
struct TripBasicsStage: View {
    @Binding var draft: TripDraft
    var onContinue: () -> Void

    @State private var showTravellerPicker = false
    @State private var showLocationPicker = false
    @State private var showCurrencyPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                livePreview

                VStack(alignment: .leading, spacing: 14) {
                    GlassField(
                        label: "Trip name",
                        placeholder: "Goa escape",
                        text: $draft.title,
                        symbol: "suitcase"
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel("Destination")

                        Button {
                            showLocationPicker = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppTheme.inkTertiary)
                                    .frame(width: 18)

                                Text(draft.destination.isEmpty ? "Search for a place" : draft.destination)
                                    .font(.system(size: 16))
                                    .foregroundStyle(draft.destination.isEmpty ? AppTheme.inkTertiary : AppTheme.ink)
                                    .lineLimit(1)

                                Spacer(minLength: 6)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AppTheme.inkTertiary)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 50)
                            .contentShape(.rect)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .panelSurface(corner: 16)
                    }
                }

                dates
                currency
                travellers

                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { continueBar }
        .sheet(isPresented: $showTravellerPicker) {
            TravellerPickerSheet(travellers: $draft.travellers)
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selection: $draft.currencyCode)
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(initial: draft.destination) { picked in
                draft.destination = picked
                // A trip with no name yet takes the destination's own — one
                // less empty field between here and a real trip.
                if draft.title.trimmingCharacters(in: .whitespaces).isEmpty {
                    draft.title = picked.components(separatedBy: ",")[0]
                }
            }
        }
    }

    // MARK: - Preview

    /// The cover resolves as you type the destination. It turns an admin form
    /// into something that feels like the trip is already real.
    private var livePreview: some View {
        DestinationImage(
            query: draft.destination.count >= 3 ? draft.destination : nil,
            fallbackSymbol: draft.inferredSymbol,
            fallbackTint: draft.inferredTint,
            onResolve: { draft.cover = $0 }
        )
        .frame(height: 132)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text(draft.title.isEmpty ? "Your trip" : draft.title)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(previewSubtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .lineLimit(1)
            .shadow(color: .black.opacity(0.45), radius: 6, y: 1)
            .padding(14)
        }
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                .frame(height: 70)
                .allowsHitTesting(false)
        }
        .clipShape(.rect(cornerRadius: 22, style: .continuous))
        .animation(.easeOut(duration: 0.3), value: draft.cover)
    }

    private var previewSubtitle: String {
        let span = "\(DateFormatter.cached("d MMM").string(from: draft.startDate)) – \(DateFormatter.cached("d MMM").string(from: draft.endDate))"
        let nights = draft.dayCount == 1 ? "1 day" : "\(draft.dayCount) days"
        return "\(span) · \(nights)"
    }

    // MARK: - Dates

    private var dates: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Dates")

            VStack(spacing: 0) {
                DatePicker(
                    "Starts",
                    selection: $draft.startDate,
                    displayedComponents: .date
                )
                .padding(.horizontal, 14)
                .frame(height: 52)

                Hairline(inset: 14)

                DatePicker(
                    "Ends",
                    selection: $draft.endDate,
                    in: draft.startDate...,
                    displayedComponents: .date
                )
                .padding(.horizontal, 14)
                .frame(height: 52)
            }
            .font(.system(size: 15))
            .tint(AppTheme.accent)
            .panelSurface(corner: 18)
            .onChange(of: draft.startDate) { _, start in
                // Keep the range valid without silently discarding a longer trip.
                if draft.endDate < start {
                    draft.endDate = Calendar.current.date(byAdding: .day, value: 2, to: start) ?? start
                }
            }
        }
    }

    // MARK: - Currency

    private var currency: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Currency")

            CurrencyRow(code: draft.currencyCode) { showCurrencyPicker = true }
        }
    }

    // MARK: - Travellers

    private var travellers: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Who's coming")

            TravellerSummaryRow(travellers: draft.travellers) {
                showTravellerPicker = true
            }
        }
    }

    // MARK: - Chrome

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppTheme.inkSecondary)
    }

    private var continueBar: some View {
        Button(action: onContinue) {
            HStack(spacing: 7) {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.glassProminent)
        .tint(AppTheme.accent)
        .disabled(!draft.isValid)
        .opacity(draft.isValid ? 1 : 0.5)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}
