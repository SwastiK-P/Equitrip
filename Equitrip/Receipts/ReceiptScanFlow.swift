//
//  ReceiptScanFlow.swift
//  Equitrip
//

import PhotosUI
import SwiftUI

/// Receipt to expense in one presentation: pick or scan, watch it read, then
/// the ordinary quick-add form fills itself in.
///
/// One cover whose content changes, rather than a picker, a reading screen and
/// a sheet presented one after another. Chained, each presentation started
/// while the last was still animating away: the reading screen lost its safe
/// area and slid under the status bar, and its task restarted mid-read, so
/// the same receipt was read twice into one reader and came out as "no text
/// found". Swapping views inside one cover can't do either.
struct ReceiptScanFlow: View {
    let trip: Trip
    var onSave: (ItineraryItem) -> Void
    /// Quick add's "Detailed" tab: Home closes this and opens the editor.
    var onSwitchToDetailed: (ItineraryItem) -> Void

    @Environment(\.dismiss) private var dismiss

    private enum Phase {
        case choosing
        case scanning
        case reading([UIImage], alreadyRectified: Bool)
        case adding(QuickAddSheet.Seed, day: Date)
    }

    @State private var phase: Phase = .choosing
    /// Bumped for every capture, so a retried read gets a fresh reading view
    /// and a fresh reader rather than reusing the finished one.
    @State private var attempt = 0
    @State private var picked: PhotosPickerItem?

    var body: some View {
        ZStack {
            CanvasBackground().ignoresSafeArea()

            switch phase {
            case .choosing:
                choosing
                    .transition(.opacity)

            case .scanning:
                ReceiptCamera(
                    onFinish: { pages in read(pages, alreadyRectified: true) },
                    onCancel: { withAnimation(.smooth) { phase = .choosing } }
                )
                .ignoresSafeArea()
                .transition(.opacity)

            case .reading(let captures, let rectified):
                ReceiptReadingView(
                    captures: captures,
                    alreadyRectified: rectified,
                    onRead: { scan, pages in
                        let day = day(for: scan)
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                            phase = .adding(QuickAddSheet.Seed(scan: scan, pages: pages, day: day, tripCurrency: trip.currencyCode), day: day)
                        }
                    },
                    onCancel: { dismiss() },
                    onRetry: { withAnimation(.smooth) { phase = .choosing } }
                )
                .id(attempt)
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity.combined(with: .scale(scale: 0.94))
                ))

            case .adding(let seed, let day):
                QuickAddSheet(
                    travellers: trip.travellers,
                    currencyCode: trip.currencyCode,
                    day: day,
                    seed: seed,
                    onSave: onSave,
                    onSwitchToDetailed: onSwitchToDetailed
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .onChange(of: picked) { _, item in
            guard let item else { return }
            picked = nil
            Task { @MainActor in
                guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
                read([image], alreadyRectified: false)
            }
        }
    }

    // MARK: - Choosing

    /// The photo library right on the screen, with the camera above it where
    /// there is one. A screenshot of a delivery app's bill is as common as
    /// paper, so the library isn't tucked behind a second button.
    private var choosing: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add a receipt")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Label("Read on this iPhone, filled in for you", systemImage: "lock.shield")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                }

                Spacer(minLength: 8)

                CircleGlyphButton(symbol: "xmark", size: 38) { dismiss() }
                    .accessibilityLabel("Close")
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            if ReceiptCamera.isAvailable {
                PrimaryButton(title: "Scan with camera", systemImage: "camera.viewfinder") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.smooth) { phase = .scanning }
                }
                .padding(.horizontal, 20)
            }

            PhotosPicker(selection: $picked, matching: .images, photoLibrary: .shared()) {
                EmptyView()
            }
            .photosPickerStyle(.inline)
            .photosPickerDisabledCapabilities([.selectionActions, .stagingArea])
            .photosPickerAccessoryVisibility(.hidden, edges: .top)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(.horizontal, 12)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func read(_ captures: [UIImage], alreadyRectified: Bool) {
        attempt += 1
        withAnimation(.smooth(duration: 0.35)) {
            phase = .reading(captures, alreadyRectified: alreadyRectified)
        }
    }

    /// The printed date when it's one of the trip's days; otherwise today on
    /// a running trip, or the trip's first day.
    private func day(for scan: ReceiptScan) -> Date {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: trip.startDate)
        let end = calendar.startOfDay(for: trip.endDate)
        if let printed = scan.date.map({ calendar.startOfDay(for: $0) }), (start...end).contains(printed) {
            return printed
        }
        let today = calendar.startOfDay(for: Date())
        return (start...end).contains(today) ? today : start
    }
}
