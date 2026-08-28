//
//  ReceiptPreview.swift
//  Equitrip
//

import SwiftUI

/// Lets a receipt drive `fullScreenCover(item:)`.
///
/// A wrapper rather than a retroactive `Identifiable` on `URL`: conforming a
/// Foundation type app-wide to satisfy one presentation is the kind of thing
/// that collides with the standard library later.
struct ReceiptRef: Identifiable {
    let id = UUID()
    let url: URL
}

/// A receipt, full screen and zoomable.
///
/// The thumbnail on the booking is there to say a receipt exists. This is for
/// the thing people actually do with one: read the line items, check the date,
/// and find out whether the ₹4,800 on the ledger is the ₹4,800 on the paper.
/// None of that is possible at 200 points tall, and a receipt photographed on a
/// restaurant table is usually small in frame — so it opens dark, fills the
/// screen, and takes a pinch.
struct ReceiptPreview: View {
    @Environment(\.dismiss) private var dismiss

    let url: URL
    /// Whose payment this is evidence of, shown along the bottom so the image
    /// can be checked against the claim without leaving the screen.
    var caption: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
                switch phase {
                case .success(let image):
                    ZoomableImage(image: image)

                case .failure:
                    state(symbol: "exclamationmark.triangle", text: "Couldn't load that receipt")

                default:
                    ProgressView().controlSize(.large).tint(.white)
                }
            }
        }
        .overlay(alignment: .top) { topBar }
        .overlay(alignment: .bottom) { footer }
        .statusBarHidden()
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: .circle)
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Close")

            Spacer(minLength: 8)

            // The one thing worth doing with a receipt other than reading it:
            // sending it to whoever is questioning the amount.
            ShareLink(item: url) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: .circle)
            }
        }
        .environment(\.colorScheme, .dark)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var footer: some View {
        if let caption {
            Text(caption)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: .capsule)
                .environment(\.colorScheme, .dark)
                .padding(.bottom, 24)
        }
    }

    private func state(symbol: String, text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .light))
            Text(text)
                .font(.system(size: 14))
        }
        .foregroundStyle(.white.opacity(0.6))
    }
}

// MARK: - Zoom

/// Pinch, drag and double-tap, clamped so the image can't be lost off-screen.
///
/// Hand-rolled rather than wrapped around a `UIScrollView`. What's needed here
/// is small — one image, no paging, no insets to reconcile — and the
/// representable version brings a coordinator and a delegate to reproduce
/// gestures SwiftUI already has.
private struct ZoomableImage: View {
    let image: Image

    @State private var scale: CGFloat = 1
    @State private var committedScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var committedOffset: CGSize = .zero

    private let range: ClosedRange<CGFloat> = 1...6

    var body: some View {
        GeometryReader { proxy in
            image
                .resizable()
                .scaledToFit()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    // Simultaneous, not exclusive: people pinch and reposition
                    // in one continuous movement, and making them let go
                    // between the two is what makes a zoom feel stiff.
                    SimultaneousGesture(magnification, pan(in: proxy.size))
                )
                .onTapGesture(count: 2) { toggle(in: proxy.size) }
                .animation(.spring(response: 0.32, dampingFraction: 0.85), value: scale)
                .animation(.spring(response: 0.32, dampingFraction: 0.85), value: offset)
        }
        .clipped()
        .contentShape(.rect)
    }

    private var magnification: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(range.upperBound, max(range.lowerBound * 0.6, committedScale * value.magnification))
            }
            .onEnded { _ in
                // Springs back rather than sticking below 1×, so an
                // over-pinch-out doesn't strand the image small in the middle.
                scale = min(range.upperBound, max(range.lowerBound, scale))
                committedScale = scale
                if scale == 1 {
                    offset = .zero
                    committedOffset = .zero
                }
            }
    }

    private func pan(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: committedOffset.width + value.translation.width,
                    height: committedOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                offset = clamped(offset, in: size)
                committedOffset = offset
            }
    }

    private func toggle(in size: CGSize) {
        if scale > 1 {
            scale = 1
            committedScale = 1
            offset = .zero
            committedOffset = .zero
        } else {
            scale = 2.6
            committedScale = 2.6
        }
    }

    /// Keeps the image's edges from being dragged inside the frame.
    private func clamped(_ proposed: CGSize, in size: CGSize) -> CGSize {
        let slackX = max(0, (size.width * scale - size.width) / 2)
        let slackY = max(0, (size.height * scale - size.height) / 2)

        return CGSize(
            width: min(slackX, max(-slackX, proposed.width)),
            height: min(slackY, max(-slackY, proposed.height))
        )
    }
}
