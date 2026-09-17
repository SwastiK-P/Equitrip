//
//  TripEditorSheet.swift
//  Equitrip
//

import SwiftUI

/// Editing a trip after it exists.
///
/// Only the organiser gets here — the entry point is hidden for everyone else
/// — because a shared plan that anyone can silently rewrite isn't a shared
/// plan. Handing the role over is part of this screen rather than a separate
/// one, since "I'm not organising this any more" and "here's who is" are the
/// same thought.
struct TripEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Trip
    @State private var showTravellerPicker = false
    @State private var showLocationPicker = false
    @State private var showCurrencyPicker = false
    @State private var showImageSource = false
    @State private var confirmingDelete = false

    var onSave: (Trip) -> Void
    /// Nil where deleting isn't on offer. Passed in rather than reaching for
    /// the store, so the caller owns what happens to the screen it was pushed
    /// from — a trip deleted from inside its own itinerary has to pop that
    /// itinerary too.
    var onDelete: (() -> Void)?

    init(trip: Trip, onSave: @escaping (Trip) -> Void, onDelete: (() -> Void)? = nil) {
        _draft = State(initialValue: trip)
        self.onSave = onSave
        self.onDelete = onDelete
    }

    private var canSave: Bool {
        draft.title.trimmingCharacters(in: .whitespaces).count >= 2 && draft.endDate >= draft.startDate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                preview

                GlassField(
                    label: "Trip name",
                    placeholder: "Goa escape",
                    text: $draft.title,
                    symbol: "suitcase"
                )

                destination
                dates
                currency
                travellers

                if onDelete != nil { deleteButton }

                Color.clear.frame(height: 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) { header }
        .safeAreaInset(edge: .bottom) { saveBar }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selection: $draft.currencyCode)
        }
        .sheet(isPresented: $showTravellerPicker) {
            TravellerPickerSheet(
                travellers: $draft.travellers,
                organiserIDs: $draft.organiserIDs
            )
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(initial: draft.destination) { picked in
                draft.destination = picked
                // The old cover was fetched for the old place; drop it so the
                // new destination resolves its own rather than keeping a
                // photograph of somewhere the group is no longer going.
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
                        // Stored immediately rather than on save: the picture
                        // is the one thing on this screen the group sees
                        // before anything else, and a half-saved cover is
                        // worse than none.
                        if let stored = await CoverStore.shared.persist(imageData: data, for: tripID) {
                            draft.cover = stored
                        }
                    }
                }
            )
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack {
            Text("Edit trip")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    /// Deleting takes the trip away from everyone on it, so it asks — and the
    /// dialog names the trip rather than saying "this item", because the whole
    /// risk here is deleting the wrong one.
    private var deleteButton: some View {
        Button(role: .destructive) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            confirmingDelete = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                Text("Delete trip")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(AppTheme.danger)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .panelSurface(corner: 18)
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.top, 4)
        .confirmationDialog(
            "Delete \(draft.title)?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete trip", role: .destructive) {
                onDelete?()
                GlassToastCenter.shared.show(.init(
                    symbol: "trash",
                    tint: AppTheme.danger,
                    title: "Trip deleted",
                    subtitle: "\"\(draft.title)\" and everything on it is gone."
                ))
                dismiss()
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text(deleteWarning)
        }
    }

    private var deleteWarning: String {
        let bookings = draft.items.count
        let people = draft.travellers.count

        if bookings == 0 {
            return "This removes the trip for everyone on it. It can't be undone."
        }
        return "\(bookings.pluralised("booking")) and any balance between \(people.pluralised("traveller")) go with it. This can't be undone."
    }

    private var saveBar: some View {
        Button {
            draft.title = draft.title.trimmingCharacters(in: .whitespaces)
            draft.destination = draft.destination.trimmingCharacters(in: .whitespaces)
            onSave(draft)
            GlassToastCenter.shared.show(.init(
                symbol: "checkmark.circle.fill",
                tint: AppTheme.positive,
                title: "Trip updated",
                subtitle: "\"\(draft.title)\" is saved.",
                duration: .seconds(3)
            ))
            dismiss()
        } label: {
            Text("Save changes")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.glassProminent)
        .tint(AppTheme.accent)
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.5)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Sections

    /// The cover, and the way to replace it with your own photograph. A
    /// searched picture of the destination is a good default; a picture the
    /// group actually took is better, and there's no reason to make them
    /// settle for the stock one.
    private var preview: some View {
        DestinationImage(
            query: draft.destination,
            photo: draft.cover,
            fallbackSymbol: draft.symbol,
            fallbackTint: draft.tint,
            onResolve: { draft.cover = $0 }
        )
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottomLeading) {
            Text(draft.title.isEmpty ? "Untitled trip" : draft.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.45), radius: 6, y: 1)
                .padding(14)
        }
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                .frame(height: 60)
                .allowsHitTesting(false)
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
                .padding(10)
            }
            .buttonStyle(.plain)
        }
        .clipShape(.rect(cornerRadius: 20, style: .continuous))
    }

    private var destination: some View {
        VStack(alignment: .leading, spacing: 6) {
            label("Destination")

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

    private var dates: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Dates")

            VStack(spacing: 0) {
                DatePicker("Starts", selection: $draft.startDate, displayedComponents: .date)
                    .padding(.horizontal, 14)
                    .frame(height: 52)

                Hairline(inset: 14)

                DatePicker("Ends", selection: $draft.endDate, in: draft.startDate..., displayedComponents: .date)
                    .padding(.horizontal, 14)
                    .frame(height: 52)
            }
            .font(.system(size: 15))
            .tint(AppTheme.accent)
            .panelSurface(corner: 18)
            .onChange(of: draft.startDate) { _, start in
                if draft.endDate < start {
                    draft.endDate = Calendar.current.date(byAdding: .day, value: 2, to: start) ?? start
                }
            }
        }
    }

    private var currency: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Currency")

            CurrencyRow(code: draft.currencyCode) { showCurrencyPicker = true }
        }
    }

    private var travellers: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Travellers")

            TravellerSummaryRow(
                travellers: draft.travellers,
                organisers: draft.organisers
            ) {
                showTravellerPicker = true
            }

            if !draft.youAreOrganiser {
                Text("You've stepped down as organiser — you'll lose edit access when you save.")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.amber)
                    .padding(.top, 2)
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppTheme.inkSecondary)
    }
}
