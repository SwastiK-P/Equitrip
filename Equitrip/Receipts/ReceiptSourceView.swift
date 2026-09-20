//
//  ReceiptSourceView.swift
//  Equitrip
//

import PhotosUI
import SwiftUI

/// Where a receipt comes from: paper through the camera, or a picture already
/// in the library.
///
/// The two sources need different help. Paper is the one that can go wrong,
/// because it reads only when it's flat, lit and fully in frame, so the camera
/// gets a card that shows the scanner closing on a page instead of a bare
/// button. The library stays open underneath because a delivery app's bill
/// arrives as a screenshot, and on a trip that screenshot is buried under a
/// day of photographs. That's what the Screenshots filter is for.
///
/// The header sits exactly where `ReceiptReadingView`'s does, so picking a
/// photo reads as the title changing rather than a new screen arriving.
struct ReceiptSourceView: View {
    let trip: Trip
    @Binding var picked: PhotosPickerItem?
    /// A picked photo is still coming off the library, or down from iCloud.
    var isOpening: Bool
    var onScan: () -> Void
    var onClose: () -> Void

    @Environment(\.pane) private var pane
    @Environment(\.tripStore) private var store

    @State private var filter: Filter = .all
    @Namespace private var filterSelection

    private enum Filter: CaseIterable {
        case all, screenshots

        var title: String {
            switch self {
            case .all: "All"
            case .screenshots: "Screenshots"
            }
        }

        var photos: PHPickerFilter {
            switch self {
            case .all: .images
            case .screenshots: .screenshots
            }
        }
    }

    private var canScan: Bool { ReceiptCamera.isAvailable }

    /// Camera and library side by side, on a full-width iPad.
    ///
    /// Only there: at a portrait 11" or a Split View third the library would
    /// be left a column too narrow for a readable grid, so those keep the
    /// phone's stack.
    private var usesColumns: Bool { canScan && pane.isWide }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 10)

            if usesColumns {
                // Two cards the same height, tops and bottoms level. The scan
                // card fills its column with the drawing rather than leaving
                // a short card over an empty rail.
                HStack(spacing: pane.columnSpacing) {
                    scanCard(tall: true)
                        .frame(width: pane.railWidth)
                    libraryCard
                }
                // The header's margin, not the pane's gutter: the reading
                // screen's header is at 20 too, and this one has to stay put.
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 16)
            } else {
                if canScan {
                    scanCard(tall: false)
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                }
                VStack(alignment: .leading, spacing: 12) {
                    libraryHeader
                        .padding(.horizontal, 8)
                    libraryTray
                }
                .padding(.horizontal, 12)
                .padding(.top, canScan ? 26 : 22)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Add a receipt")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                HStack(spacing: 6) {
                    DestinationImage(
                        query: trip.destination,
                        photo: trip.cover,
                        fallbackSymbol: trip.symbol,
                        fallbackTint: trip.tint,
                        onResolve: { store.setCover($0, for: trip.id) }
                    )
                    .frame(width: 16, height: 16)
                    .clipShape(.circle)
                    .accessibilityHidden(true)

                    Text("For \(Text(trip.title).fontWeight(.semibold).foregroundStyle(AppTheme.inkSecondary))")
                        .lineLimit(1)
                }
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 38, action: onClose)
                .accessibilityLabel("Close")
        }
    }

    // MARK: - Camera

    /// Shorter on a small phone, so the library still gets a few rows.
    ///
    /// Held here rather than grown for breathing room: the inline photo
    /// picker drops from three columns to five once it's much shorter than
    /// this leaves it, and receipts are unreadable at five. The room around
    /// the paper comes from drawing the paper smaller instead.
    private var stageHeight: CGFloat { pane.height < 740 ? 128 : 156 }

    /// `tall` fills an iPad column: the stage takes all the height the
    /// caption doesn't, and the paper is drawn up to about twice its phone
    /// size to match.
    private func scanCard(tall: Bool) -> some View {
        Button(action: onScan) {
            VStack(spacing: 0) {
                Group {
                    if tall {
                        GeometryReader { proxy in
                            ReceiptScanPreview()
                                .scaleEffect(min(2.1, proxy.size.width / 190, proxy.size.height / 250))
                                .frame(width: proxy.size.width, height: proxy.size.height)
                        }
                    } else {
                        ReceiptScanPreview()
                            .scaleEffect(pane.height < 740 ? 0.78 : 0.92)
                            .frame(maxWidth: .infinity)
                            .frame(height: stageHeight)
                    }
                }
                .background(
                    AppTheme.canvasBottom.opacity(0.6),
                    in: .rect(cornerRadius: 18, style: .continuous)
                )
                .clipShape(.rect(cornerRadius: 18, style: .continuous))
                .padding(6)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Scan a paper receipt")
                            .font(.system(size: 16.5, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)

                        // Two sentences, two lines: left to wrap, the second
                        // one broke with two words on a line of their own.
                        Text("Lay it flat, in good light.\nLong ones take a few shots.")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    // Glass tinted the CTA's near-black, so it still reads as
                    // the one action on the card. Not `.interactive()`: the
                    // whole card is the button, and a glass that answers
                    // touches on its own would react separately from it.
                    Image(systemName: "camera")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.ctaLabel)
                        .frame(width: 42, height: 42)
                        .glassEffect(.regular.tint(AppTheme.cta), in: .circle)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 15)
            }
            .contentShape(.rect(cornerRadius: 24, style: .continuous))
            .cardSurface(corner: 24)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Scan a paper receipt")
        .accessibilityHint("Opens the camera")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Library

    private var libraryHeader: some View {
        HStack(alignment: .center) {
            Text("From your photos")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Spacer(minLength: 8)

            filterControl
        }
    }

    /// The phone's library: a tray rising off the bottom of the screen.
    private var libraryTray: some View {
        photoGrid(bottomCorner: 0)
            .padding([.horizontal, .top], 6)
            .background {
                UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24, style: .continuous)
                    .fill(AppTheme.card)
                    .shadow(color: AppTheme.softShadow(.light), radius: 14, y: -1)
            }
            .ignoresSafeArea(edges: .bottom)
    }

    /// The iPad's library: a card level with the scan card beside it, so
    /// the heading moves inside and both columns start on the same line.
    private var libraryCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            libraryHeader
                .padding(.leading, 18)
                .padding(.trailing, 12)
                .padding(.top, 14)
                .padding(.bottom, 12)

            photoGrid(bottomCorner: 18)
                .padding([.horizontal, .bottom], 6)
        }
        .cardSurface(corner: 24)
    }

    private var filterControl: some View {
        HStack(spacing: 0) {
            ForEach(Filter.allCases, id: \.self) { option in
                let isOn = filter == option
                Button {
                    guard !isOn else { return }
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) { filter = option }
                } label: {
                    Text(option.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isOn ? AppTheme.ink : AppTheme.inkSecondary)
                        .padding(.horizontal, 12)
                        .frame(height: 28)
                        .background {
                            if isOn {
                                Capsule()
                                    .fill(AppTheme.card)
                                    .shadow(color: AppTheme.softShadow(.light), radius: 3, y: 1)
                                    .matchedGeometryEffect(id: "filter", in: filterSelection)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(3)
        .background(AppTheme.cardStroke.opacity(0.06), in: .capsule)
    }

    /// The system's own picker, inline, with its chrome off: no albums bar,
    /// no options menu, no "Location Included" — here it's a grid of pictures
    /// and nothing else.
    ///
    /// Rebuilt when the filter changes. The inline picker takes its filter
    /// once, when it's made, and ignores a new one after that.
    private func photoGrid(bottomCorner: CGFloat) -> some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 18,
            bottomLeadingRadius: bottomCorner,
            bottomTrailingRadius: bottomCorner,
            topTrailingRadius: 18,
            style: .continuous
        )

        return PhotosPicker(selection: $picked, matching: filter.photos, photoLibrary: .shared()) {
            EmptyView()
        }
        .photosPickerStyle(.inline)
        .photosPickerDisabledCapabilities([.selectionActions, .stagingArea])
        .photosPickerAccessoryVisibility(.hidden, edges: .all)
        .id(filter)
        .transition(.opacity)
        .clipShape(shape)
        .overlay {
            if isOpening {
                opening
                    .clipShape(shape)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: isOpening)
    }

    private var opening: some View {
        ZStack {
            AppTheme.card.opacity(0.82)

            VStack(spacing: 10) {
                ProgressView()
                    .tint(AppTheme.inkSecondary)
                Text("Opening photo")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
            }
        }
    }
}

// MARK: - Scan preview

/// A receipt on a table, being scanned over and over.
///
/// What the document camera and the reader will actually do, drawn small, as
/// one loop: the corners close on the paper, a line sweeps down it, and each
/// row takes the colour `ReceiptReadingView` gives it next (items indigo, the
/// charge amber, the total green). Then the corners let go and the paper is
/// put down again at a slightly different angle. Showing the page flat,
/// whole and lit does more than a sentence of instructions would. With
/// Reduce Motion it stays still, found and unread.
///
/// It has no merchant, items or prices because it's a picture of *a*
/// receipt, and text in it would read as someone's data.
private struct ReceiptScanPreview: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var settled = false
    /// Alternates each pass, so the paper looks put down again rather than
    /// stuck in one place.
    @State private var replaced = false
    @State private var found = false
    @State private var sweep: CGFloat = 0
    @State private var sweepShown = false
    /// Rows coloured so far, top to bottom.
    @State private var lit = 0

    private let paper = CGSize(width: 98, height: 116)
    private let band: CGFloat = 30
    private let sweepDuration = 1.7

    var body: some View {
        ReceiptPaper(lit: lit)
            .frame(width: paper.width, height: paper.height)
            .overlay { sweepLine }
            .overlay {
                ScanCorners()
                    .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .padding(found ? -8 : -24)
                    .opacity(found ? 1 : 0)
            }
            .rotationEffect(.degrees(settled ? (replaced ? -1.5 : -4) : -9))
            // A little above centre: the shadow falls below the paper, and
            // the torn edge needs the room more than the top does.
            .offset(x: replaced ? 3 : 0, y: settled ? -3 : 6)
            .accessibilityHidden(true)
            .task { await play() }
    }

    /// The reading screen's sweep, at this size: a line with a short glow
    /// trailing above it, clipped to the paper.
    private var sweepLine: some View {
        LinearGradient(
            colors: [AppTheme.accent.opacity(0), AppTheme.accent.opacity(0.16)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: band)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.accent.opacity(0.75)).frame(height: 1.5)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .offset(y: -band + sweep * (paper.height + band))
        .opacity(sweepShown ? 1 : 0)
        .clipShape(ReceiptPaperShape())
    }

    private func play() async {
        guard !reduceMotion else {
            settled = true
            found = true
            return
        }
        do {
            try await Task.sleep(for: .milliseconds(180))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { settled = true }

            while true {
                try await Task.sleep(for: .milliseconds(480))
                withAnimation(.spring(response: 0.62, dampingFraction: 0.74)) { found = true }
                try await Task.sleep(for: .milliseconds(560))

                try await read()
                try await Task.sleep(for: .seconds(2))

                withAnimation(.easeInOut(duration: 0.6)) {
                    found = false
                    lit = 0
                }
                try await Task.sleep(for: .milliseconds(340))
                withAnimation(.spring(response: 1, dampingFraction: 0.82)) { replaced.toggle() }
                try await Task.sleep(for: .milliseconds(850))
            }
        } catch {
            // Cancelled: the card went away.
        }
    }

    /// One sweep, colouring each row as the line crosses it.
    private func read() async throws {
        // Where each row's middle sits on the paper, top to bottom: three
        // items, the charge, the total. See `ReceiptPaper`.
        let rows: [CGFloat] = [36, 45, 54, 63, 83.5]

        withAnimation(.easeOut(duration: 0.2)) { sweepShown = true }
        withAnimation(.linear(duration: sweepDuration)) { sweep = 1 }

        var elapsed = 0.0
        for (index, y) in rows.enumerated() {
            let crossing = sweepDuration * Double(y / (paper.height + band))
            try await Task.sleep(for: .seconds(crossing - elapsed))
            elapsed = crossing
            withAnimation(.easeOut(duration: 0.35)) { lit = index + 1 }
        }

        try await Task.sleep(for: .seconds(sweepDuration - elapsed))
        withAnimation(.easeOut(duration: 0.25)) { sweepShown = false }
        try await Task.sleep(for: .milliseconds(280))
        // Back to the top while it's invisible. Reset in the same update as
        // the next sweep's start and it would animate from 1 to 1.
        sweep = 0
    }
}

/// The printed side: a heading, three items and a charge, a rule and a
/// total, drawn as thermal-grey strokes that take the reader's colours as
/// they're read.
private struct ReceiptPaper: View {
    /// How many of the five rows have been read, from the top.
    var lit: Int

    var body: some View {
        VStack(spacing: 0) {
            Capsule().frame(width: 34, height: 4).opacity(0.42)
            Capsule().frame(width: 22, height: 2.5).opacity(0.16)
                .padding(.top, 4)

            VStack(spacing: 6) {
                line(38, 12, row: 0, tint: AppTheme.accent)
                line(26, 14, row: 1, tint: AppTheme.accent)
                line(44, 10, row: 2, tint: AppTheme.accent)
                line(30, 12, row: 3, tint: Palette.amber)
            }
            .padding(.top, 12)

            Line()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [2.5, 2]))
                .frame(height: 1)
                .opacity(0.22)
                .padding(.top, 9)

            HStack {
                Capsule().frame(width: 24, height: 4)
                Spacer(minLength: 4)
                Capsule().frame(width: 20, height: 4)
            }
            .foregroundStyle(lit > 4 ? AppTheme.positive : AppTheme.ink)
            .opacity(lit > 4 ? 0.85 : 0.5)
            .padding(.top, 7)

            Spacer(minLength: 0)
        }
        .foregroundStyle(AppTheme.ink)
        .padding(.horizontal, 11)
        .padding(.top, 12)
        .background {
            ReceiptPaperShape()
                .fill(.white)
                .shadow(color: Color(red: 0.35, green: 0.2, blue: 0.1).opacity(0.08), radius: 1.5, y: 1)
                .shadow(color: Color(red: 0.35, green: 0.2, blue: 0.1).opacity(0.16), radius: 10, x: 2, y: 8)
        }
    }

    private func line(_ item: CGFloat, _ price: CGFloat, row: Int, tint: Color) -> some View {
        let isLit = lit > row
        return HStack {
            Capsule().frame(width: item, height: 3)
            Spacer(minLength: 4)
            Capsule().frame(width: price, height: 3)
        }
        .foregroundStyle(isLit ? tint : AppTheme.ink)
        .opacity(isLit ? 0.6 : 0.17)
    }
}

/// A slip of till roll: square top, torn into teeth along the bottom.
private struct ReceiptPaperShape: Shape {
    var tooth: CGFloat = 7
    var depth: CGFloat = 3.5

    func path(in rect: CGRect) -> Path {
        let corner: CGFloat = 2
        let teeth = max(1, Int((rect.width / tooth).rounded()))
        let width = rect.width / CGFloat(teeth)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - depth))
        path.addArc(
            tangent1End: CGPoint(x: rect.minX, y: rect.minY),
            tangent2End: CGPoint(x: rect.maxX, y: rect.minY),
            radius: corner
        )
        path.addArc(
            tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
            tangent2End: CGPoint(x: rect.maxX, y: rect.maxY),
            radius: corner
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - depth))
        for index in 0..<teeth {
            let right = rect.maxX - CGFloat(index) * width
            path.addLine(to: CGPoint(x: right - width / 2, y: rect.maxY))
            path.addLine(to: CGPoint(x: right - width, y: rect.maxY - depth))
        }
        path.closeSubpath()
        return path
    }
}

/// The four corner marks the document camera draws around a page it has found.
private struct ScanCorners: Shape {
    var arm: CGFloat = 14
    var radius: CGFloat = 5

    func path(in rect: CGRect) -> Path {
        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            (CGPoint(x: rect.minX, y: rect.minY + arm), CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.minX + arm, y: rect.minY)),
            (CGPoint(x: rect.maxX - arm, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY + arm)),
            (CGPoint(x: rect.maxX, y: rect.maxY - arm), CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.maxX - arm, y: rect.maxY)),
            (CGPoint(x: rect.minX + arm, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY - arm))
        ]

        var path = Path()
        for (start, corner, end) in corners {
            path.move(to: start)
            path.addArc(tangent1End: corner, tangent2End: end, radius: radius)
            path.addLine(to: end)
        }
        return path
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}
