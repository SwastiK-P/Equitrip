//
//  TripReviewStage.swift
//  Equitrip
//

import SwiftUI

/// The last stop before a trip becomes the group's shared record.
///
/// Everything here is editable, including everything the model produced. That
/// matters more for the import route than the manual one: an extraction that
/// can't be corrected is worse than no extraction, because the errors become
/// someone else's money.
struct TripReviewStage: View {
    @Binding var draft: TripDraft
    var onCreate: () -> Void

    @State private var editingItem: ItineraryItem?
    @State private var isAddingItem = false
    @State private var showTravellerPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                cover

                if draft.wasImported { importNote }

                travellers
                bookings
                totals

                Color.clear.frame(height: 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) { createBar }
        .sheet(isPresented: $showTravellerPicker) {
            TravellerPickerSheet(travellers: $draft.travellers)
        }
        .sheet(item: $editingItem) { item in
            ItineraryItemEditor(
                item: item,
                travellers: draft.travellers,
                currencyCode: draft.currencyCode,
                onSave: { updated in
                    if let index = draft.items.firstIndex(where: { $0.id == updated.id }) {
                        draft.items[index] = updated
                    }
                },
                onDelete: {
                    withAnimation { draft.items.removeAll { $0.id == item.id } }
                }
            )
        }
        .sheet(isPresented: $isAddingItem) {
            ItineraryItemEditor(
                item: ItineraryItem(
                    title: "",
                    date: draft.startDate,
                    participantIDs: Set(draft.travellers.map(\.id))
                ),
                travellers: draft.travellers,
                currencyCode: draft.currencyCode,
                isNew: true,
                onSave: { new in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        draft.items.append(new)
                        expandSpanToFit(new)
                    }
                }
            )
        }
    }

    // MARK: - Cover

    private var cover: some View {
        DestinationImage(
            query: draft.coverQuery,
            photo: draft.cover,
            fallbackSymbol: draft.inferredSymbol,
            fallbackTint: draft.inferredTint,
            onResolve: { draft.cover = $0 }
        )
        .frame(height: 168)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 3) {
                Text(draft.title.isEmpty ? "Untitled trip" : draft.title)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 11, weight: .semibold))
                    Text(draft.destination.isEmpty ? "No destination set" : draft.destination)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.9))
            }
            .lineLimit(1)
            .shadow(color: .black.opacity(0.45), radius: 6, y: 1)
            .padding(16)
        }
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .frame(height: 96)
                .allowsHitTesting(false)
        }
        .clipShape(.rect(cornerRadius: 24, style: .continuous))
    }

    /// Says which reader produced this, so nobody assumes an accuracy the
    /// pattern-matching path doesn't have.
    private var importNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: draft.usedFallbackParser ? "exclamationmark.circle.fill" : "apple.intelligence")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(draft.usedFallbackParser ? Palette.amber : AppTheme.accent)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(draft.usedFallbackParser ? "Read by pattern matching" : "Powered by Apple Intelligence")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text(
                    draft.usedFallbackParser
                        ? "Apple Intelligence wasn't available, so this is a rough pass. Check the times and amounts carefully."
                        : "Apple Intelligence pulled these out of \(draft.sourceFileName ?? "your document"). Worth a quick check before the group sees it."
                )
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .panelSurface(corner: 18)
    }

    // MARK: - Travellers

    private var travellers: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Travellers", caption: "\(draft.travellers.count)")

            TravellerSummaryRow(travellers: draft.travellers) {
                showTravellerPicker = true
            }
        }
    }

    // MARK: - Bookings

    private var bookings: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: "Bookings",
                caption: draft.items.isEmpty ? nil : "\(draft.items.count)",
                actionTitle: "Add"
            ) {
                isAddingItem = true
            }

            if draft.items.isEmpty {
                emptyBookings
            } else {
                VStack(spacing: 16) {
                    ForEach(groupedItems, id: \.0) { day, items in
                        daySection(day: day, items: items)
                    }
                }
            }
        }
    }

    private var groupedItems: [(Date, [ItineraryItem])] {
        Dictionary(grouping: draft.items.sorted(by: Trip.chronological)) { $0.day }
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value) }
    }

    private func daySection(day: Date, items: [ItineraryItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(DateFormatter.cached("EEEE d MMMM").string(from: day).uppercased())
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.leading, 2)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    Button {
                        editingItem = item
                    } label: {
                        ReviewItemRow(item: item, trip: draft)
                    }
                    .buttonStyle(PressableButtonStyle())

                    if index < items.count - 1 { Hairline(inset: 16) }
                }
            }
            .cardSurface(corner: 20)
        }
    }

    private var emptyBookings: some View {
        Button { isAddingItem = true } label: {
            VStack(spacing: 9) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.interactive(), in: .circle)

                Text("Add your first booking")
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text("Flights, stays, activities — or add them later as they're booked.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        AppTheme.cardStroke.opacity(0.16),
                        style: StrokeStyle(lineWidth: 1.5, dash: [7, 6])
                    )
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Totals

    private var totals: some View {
        VStack(spacing: 0) {
            totalRow(
                label: "Booked so far",
                value: Money.format(draft.totalCost, code: draft.currencyCode),
                emphasised: true
            )

            Hairline(inset: 16)

            totalRow(
                label: "Even split, \(draft.travellers.count.pluralised("person", "people"))",
                value: Money.format(
                    draft.travellers.isEmpty ? 0 : draft.totalCost / Double(draft.travellers.count),
                    code: draft.currencyCode
                ),
                emphasised: false
            )
        }
        .cardSurface(corner: 20)
    }

    private func totalRow(label: String, value: String, emphasised: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: emphasised ? 14.5 : 13.5, weight: emphasised ? .semibold : .regular))
                .foregroundStyle(emphasised ? AppTheme.ink : AppTheme.inkSecondary)

            Spacer(minLength: 8)

            Text(value)
                .font(.system(size: emphasised ? 17 : 14.5, weight: emphasised ? .bold : .semibold, design: .rounded))
                .foregroundStyle(emphasised ? AppTheme.ink : AppTheme.inkSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Create

    private var createBar: some View {
        Button(action: onCreate) {
            HStack(spacing: 7) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                Text("Create trip")
                    .font(.system(size: 16, weight: .semibold))
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

    /// A booking outside the current dates widens the trip rather than being
    /// silently dropped off the end of the timeline.
    private func expandSpanToFit(_ item: ItineraryItem) {
        if item.day < draft.startDate { draft.startDate = item.day }
        if item.day > draft.endDate { draft.endDate = item.day }
    }
}

// MARK: - Row

private struct ReviewItemRow: View {
    let item: ItineraryItem
    let trip: TripDraft

    var body: some View {
        HStack(spacing: 12) {
            SymbolBadge(symbol: item.symbol, tint: item.kind.tint, size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.isEmpty ? "Untitled" : item.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 2) {
                if item.cost > 0 {
                    Text(Money.format(item.cost, code: trip.currencyCode))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(.rect)
    }

    private var subtitle: String {
        var parts: [String] = []
        if let clock = item.clock { parts.append("\(clock.value) \(clock.meridiem)") }
        if !item.vendor.isEmpty { parts.append(item.vendor) }
        parts.append(item.split.label)
        return parts.joined(separator: " · ")
    }
}
