//
//  ChatBookingPicker.swift
//  Equitrip
//

import SwiftUI

/// Choosing a booking to drop into the thread — "is this the one?" with the
/// booking itself attached, rather than a description of it.
///
/// Opens on what's coming up next, since that's what people are asking about.
struct ChatBookingPicker: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    var onPick: (ItineraryItem) -> Void

    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            ChatSheetHeader(title: "Share a booking", caption: "It stays live — changes to it show in the chat.")

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                TextField("Search bookings", text: $query)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.ink)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .panelSurface(corner: 14)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            if days.isEmpty {
                VStack(spacing: 10) {
                    Spacer(minLength: 20)
                    Image(systemName: "ticket")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(AppTheme.inkTertiary)
                    Text(trip.items.isEmpty ? "Nothing's booked on this trip yet" : "No bookings match that")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.inkSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            ForEach(days) { day in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("\(day.title) · \(day.subtitle)")
                                        .font(.system(size: 12.5, weight: .semibold))
                                        .foregroundStyle(day.isToday ? AppTheme.accent : AppTheme.inkSecondary)
                                        .padding(.horizontal, 4)

                                    VStack(spacing: 0) {
                                        ForEach(day.items) { item in
                                            row(item)
                                            if item.id != day.items.last?.id { Hairline(inset: 58) }
                                        }
                                    }
                                    .cardSurface(corner: 18, shadow: 4)
                                }
                                .id(day.id)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    .onAppear {
                        if let upcoming = trip.upcoming(limit: 1).first {
                            proxy.scrollTo(upcoming.day, anchor: .top)
                        }
                    }
                }
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
    }

    private var days: [TripDay] {
        let needle = query.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return trip.days }
        return trip.days.compactMap { day in
            let matches = day.items.filter {
                $0.title.localizedStandardContains(needle) || ($0.vendorName?.localizedStandardContains(needle) ?? false)
            }
            return matches.isEmpty ? nil : TripDay(index: day.index, date: day.date, items: matches)
        }
    }

    private func row(_ item: ItineraryItem) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onPick(item)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                SymbolBadge(symbol: item.symbol, tint: item.kind.tint, size: 34)

                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                    Text([item.timeLabel, item.vendorName].compactMap { $0 }.joined(separator: " · ").ifEmpty(item.kind.label))
                        .font(.system(size: 12.5))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                if item.cost > 0 {
                    Text(Money.format(item.cost, code: trip.currencyCode))
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.inkSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}
