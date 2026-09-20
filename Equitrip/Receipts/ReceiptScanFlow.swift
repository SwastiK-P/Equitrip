//
//  ReceiptScanFlow.swift
//  Equitrip
//

import PhotosUI
import SwiftUI

/// Receipt to expense in one presentation: pick or scan, watch it read, then
/// the full booking editor opens with what was read already filled in.
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

    @Environment(\.dismiss) private var dismiss

    private enum Phase {
        case choosing
        case scanning
        case reading([UIImage], alreadyRectified: Bool)
        case adding(ItineraryItem)
    }

    @State private var phase: Phase = .choosing
    /// Bumped for every capture, so a retried read gets a fresh reading view
    /// and a fresh reader rather than reusing the finished one.
    @State private var attempt = 0
    @State private var picked: PhotosPickerItem?
    @State private var isOpening = false
    @State private var receipt = ReceiptAttachment()

    var body: some View {
        ZStack {
            CanvasBackground().ignoresSafeArea()

            switch phase {
            case .choosing:
                ReceiptSourceView(
                    trip: trip,
                    picked: $picked,
                    isOpening: isOpening,
                    onScan: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.smooth) { phase = .scanning }
                    },
                    onClose: { dismiss() }
                )
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
                        let item = ItineraryItem(scan: scan, travellers: trip.travellers)
                        receipt.upload(pages, for: item.id)
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                            phase = .adding(item)
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

            case .adding(let item):
                ItineraryItemEditor(
                    item: item,
                    travellers: trip.travellers,
                    currencyCode: trip.currencyCode,
                    isNew: true,
                    onSave: { [receipt, onSave] saved in receipt.save(saved, through: onSave) }
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
            // One photo at a time: a second tap while the first is still
            // coming down from iCloud would start a second read.
            guard !isOpening else { return }
            isOpening = true
            Task { @MainActor in
                defer { isOpening = false }
                guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    return
                }
                read([image], alreadyRectified: false)
            }
        }
    }

    private func read(_ captures: [UIImage], alreadyRectified: Bool) {
        attempt += 1
        withAnimation(.smooth(duration: 0.35)) {
            phase = .reading(captures, alreadyRectified: alreadyRectified)
        }
    }
}

/// Gets the receipt photo onto the booking without making anyone wait for it.
///
/// The upload starts the moment the scan is read, while the editor is still
/// open, and the booking saves without it. The editor saves more than once
/// (its glyph lookup re-saves), and every save is a full upsert, so whichever
/// save lands last has to carry the URL — this remembers both the URL and
/// the latest booking so neither can overwrite the other. A class, because it
/// outlives the cover it was made in.
@MainActor
private final class ReceiptAttachment {
    private var url: URL?
    private var latest: ItineraryItem?
    private var save: ((ItineraryItem) -> Void)?

    func upload(_ pages: [UIImage], for itemID: UUID) {
        guard let photo = ReceiptImagePrep.combined(pages),
              let data = photo.jpegForUpload(maxDimension: 2600, quality: 0.72) else { return }
        Task {
            // A failed upload leaves the booking as it is.
            guard let uploaded = try? await MediaStore.shared.uploadReceipt(data, for: itemID) else { return }
            url = uploaded
            if var item = latest, item.receiptURL == nil {
                item.receiptURL = uploaded
                self.save(item, through: save)
            }
        }
    }

    func save(_ item: ItineraryItem, through onSave: ((ItineraryItem) -> Void)?) {
        var item = item
        if item.receiptURL == nil { item.receiptURL = url }
        latest = item
        save = onSave
        onSave?(item)
    }
}
