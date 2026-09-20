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
///
/// The screen used to be a stack of labelled rows — two system date pickers,
/// a currency row, a traveller row — which is a form, and forms are where
/// planning a holiday goes to feel like filing an expense claim. Everything
/// that could be shown as an object now is: the cover resolves as you type the
/// destination, the dates are two cards with the night count strung between
/// them, and the currency is a row of symbols you tap rather than a list you
/// open.
struct TripBasicsStage: View {
    @Binding var draft: TripDraft
    var onContinue: () -> Void

    @State private var showTravellerPicker = false
    @State private var showLocationPicker = false
    @State private var showCurrencyPicker = false
    @State private var showImageSource = false
    @State private var editingDate: DateSlot?
    @State private var appeared = false

    enum DateSlot: String, Identifiable {
        case start, end
        var id: String { rawValue }
        var title: String { self == .start ? "Starts" : "Ends" }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                livePreview
                    .staggered(0, appeared)

                identity
                    .staggered(1, appeared)

                dates
                    .staggered(2, appeared)

                currency
                    .staggered(3, appeared)

                travellers
                    .staggered(4, appeared)

                customize
                    .staggered(5, appeared)

                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { continueBar }
        .onAppear { withAnimation { appeared = true } }
        .sheet(isPresented: $showTravellerPicker) {
            TravellerPickerSheet(travellers: $draft.travellers)
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selection: $draft.currencyCode)
        }
        .sheet(item: $editingDate) { slot in
            DateSlotSheet(
                slot: slot,
                date: slot == .start ? $draft.startDate : $draft.endDate,
                earliest: slot == .end ? draft.startDate : nil
            )
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(initial: draft.destination) { picked in
                draft.destination = picked
                // A trip with no name yet takes the destination's own — one
                // less empty field between here and a real trip.
                if draft.title.trimmingCharacters(in: .whitespaces).isEmpty {
                    draft.title = picked.components(separatedBy: ",")[0]
                }
                // The old cover, if any, was fetched for the old place.
                draft.cover = nil
            }
        }
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
        .onChange(of: draft.startDate) { _, start in
            // Keep the range valid without silently discarding a longer trip.
            if draft.endDate < start {
                draft.endDate = Calendar.current.date(byAdding: .day, value: 2, to: start) ?? start
            }
        }
    }

    // MARK: - Preview

    /// The cover resolves as you type the destination. It turns an admin form
    /// into something that feels like the trip is already real.
    private var livePreview: some View {
        DestinationImage(
            query: draft.destination.count >= 3 ? draft.destination : nil,
            photo: draft.cover,
            fallbackSymbol: draft.inferredSymbol,
            fallbackTint: draft.inferredTint,
            onResolve: { draft.cover = $0 }
        )
        .frame(height: 172)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.clear, .black.opacity(0.62)], startPoint: .top, endPoint: .bottom)
                .frame(height: 110)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topLeading) {
            // Sits on the picture rather than under it: this is the trip's own
            // badge, and it changes as the destination is typed.
            HStack(spacing: 6) {
                Image(systemName: draft.inferredSymbol)
                    .font(.system(size: 11, weight: .bold))
                Text(draft.dayCount == 1 ? "1 day" : "\(draft.dayCount) days")
                    .font(.system(size: 11.5, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.28), in: .capsule)
            .background(.ultraThinMaterial, in: .capsule)
            .padding(14)
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 3) {
                Text(draft.title.isEmpty ? "Your trip" : draft.title)
                    .tripTitle(draft.titleStyle, size: 23)
                    .foregroundStyle(.white)

                HStack(spacing: 5) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10.5, weight: .bold))
                    Text(draft.destination.isEmpty ? "Pick a destination" : draft.destination)
                        .font(.system(size: 12.5, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.88))
            }
            .lineLimit(1)
            .shadow(color: .black.opacity(0.45), radius: 6, y: 1)
            .padding(16)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showImageSource = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Change")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.4), in: .capsule)
                .padding(14)
            }
            .buttonStyle(.plain)
        }
        .clipShape(.rect(cornerRadius: 24, style: .continuous))
        .shadow(color: AppTheme.softShadow(.light), radius: 14, y: 6)
        .animation(.easeOut(duration: 0.3), value: draft.cover)
        .animation(.easeOut(duration: 0.25), value: draft.inferredSymbol)
    }

    // MARK: - Identity

    private var identity: some View {
        VStack(alignment: .leading, spacing: 12) {
            GlassField(
                label: "Trip name",
                placeholder: "Goa escape",
                text: $draft.title,
                symbol: "suitcase"
            )

            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Destination")

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
    }

    // MARK: - Dates

    /// Two cards with the length of the trip strung between them.
    ///
    /// The system's inline date pickers put two grey pills on the page and
    /// made you read them to work out how long the trip was. Here the two ends
    /// are the same object — a torn-off date — and the answer to "how long?"
    /// sits between them where the question is asked.
    private var dates: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("When")

            HStack(spacing: 0) {
                dateCard(.start, date: draft.startDate)

                VStack(spacing: 3) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.inkTertiary)

                    Text(draft.dayCount == 1 ? "1 day" : "\(draft.dayCount) days")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                        .fixedSize()
                }
                .frame(width: 54)

                dateCard(.end, date: draft.endDate)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.86), value: draft.dayCount)

            durationChips
        }
    }

    private func dateCard(_ slot: DateSlot, date: Date) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            editingDate = slot
        } label: {
            VStack(spacing: 2) {
                Text(slot.title.uppercased())
                    .font(.system(size: 9.5, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(AppTheme.inkTertiary)

                Text(DateFormatter.cached("d").string(from: date))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .contentTransition(.numericText())

                Text(DateFormatter.cached("MMM yyyy").string(from: date))
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(AppTheme.inkSecondary)

                Text(DateFormatter.cached("EEEE").string(from: date))
                    .font(.system(size: 10.5))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .panelSurface(corner: 18)
    }

    /// The four trip lengths people actually pick. One tap moves the end date;
    /// anything unusual still goes through the calendar.
    private var durationChips: some View {
        HStack(spacing: 8) {
            ForEach(Self.durations, id: \.days) { option in
                let on = draft.dayCount == option.days

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        draft.endDate = Calendar.current.date(
                            byAdding: .day,
                            value: option.days - 1,
                            to: draft.startDate
                        ) ?? draft.startDate
                    }
                } label: {
                    Text(option.label)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(on ? AppTheme.ctaLabel : AppTheme.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            Capsule().fill(on ? AnyShapeStyle(AppTheme.cta) : AnyShapeStyle(.clear))
                        }
                        .overlay {
                            Capsule().strokeBorder(AppTheme.cardStroke.opacity(on ? 0 : 0.09))
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private static let durations: [(label: String, days: Int)] = [
        ("Weekend", 2), ("5 days", 5), ("A week", 7), ("2 weeks", 14)
    ]

    // MARK: - Currency

    /// The eight codes the app already knows, as symbols. A picker is still
    /// one tap away for everything else, but a group in India picking rupees
    /// shouldn't have to open a list to do it.
    private var currency: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("Currency")

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Money.common, id: \.self) { code in
                        currencyChip(code)
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showCurrencyPicker = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 11, weight: .bold))
                            Text("More")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 13)
                        .frame(height: 46)
                        .contentShape(.capsule)
                        .overlay {
                            Capsule().strokeBorder(AppTheme.accent.opacity(0.28))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func currencyChip(_ code: String) -> some View {
        let on = draft.currencyCode == code

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                draft.currencyCode = code
            }
        } label: {
            VStack(spacing: 0) {
                Text(Money.symbol(for: code))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text(code)
                    .font(.system(size: 10, weight: .semibold))
                    .opacity(0.75)
            }
            .foregroundStyle(on ? AppTheme.ctaLabel : AppTheme.inkSecondary)
            .frame(width: 54, height: 46)
            .background {
                Capsule().fill(on ? AnyShapeStyle(AppTheme.cta) : AnyShapeStyle(AppTheme.card.opacity(0.7)))
            }
            .overlay {
                Capsule().strokeBorder(AppTheme.cardStroke.opacity(on ? 0 : 0.07))
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Travellers

    private var travellers: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("Who's coming")

            TravellerSummaryRow(travellers: draft.travellers) {
                showTravellerPicker = true
            }
        }
    }

    // MARK: - Chrome

    /// How the trip's name is set, shown on the preview at the top as it's picked.
    private var customize: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Customize")
            TripTitleStylePicker(title: draft.title, selection: $draft.titleStyle)
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .bold))
            .tracking(0.9)
            .foregroundStyle(AppTheme.inkTertiary)
            .padding(.leading, 2)
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

// MARK: - Date sheet

/// One end of the trip, on a full calendar.
///
/// A sheet rather than an inline picker: the graphical calendar is the right
/// control for choosing a date you're picturing rather than reciting, and it's
/// far too tall to leave sitting in the middle of the form.
private struct DateSlotSheet: View {
    @Environment(\.dismiss) private var dismiss

    let slot: TripBasicsStage.DateSlot
    @Binding var date: Date
    /// The start date, when this is the end of the trip — a trip can't finish
    /// before it begins, and the calendar should say so rather than let it be
    /// picked and quietly corrected afterwards.
    var earliest: Date?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(slot.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Spacer(minLength: 8)

                CircleGlyphButton(symbol: "checkmark", size: 34) { dismiss() }
                    .accessibilityLabel("Done")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)

            Group {
                if let earliest {
                    DatePicker("", selection: $date, in: earliest..., displayedComponents: .date)
                } else {
                    DatePicker("", selection: $date, displayedComponents: .date)
                }
            }
            .datePickerStyle(.graphical)
            .labelsHidden()
            .tint(AppTheme.accent)
            .padding(.horizontal, 12)
            // The graphical picker draws its own month header flush against
            // its top edge, which — with no gap here — got clipped under the
            // sheet's own title row instead of sitting below it.
            .padding(.top, 6)

            Spacer(minLength: 0)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
    }
}
