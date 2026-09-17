//
//  ReceiptReadingView.swift
//  Equitrip
//

import SwiftUI

/// The receipt, being read: every line found lights up where it sits on the paper.
///
/// Worth the two seconds it asks for. A figure that appears pre-filled with no
/// visible reading behind it is a figure people re-type out of suspicion; one
/// they watched come off the page — items blue, charges amber, the total green
/// — is one they check at a glance and trust.
///
/// It owns the read: presented with the captures, it hands back the finished
/// scan once the colours have had a moment on screen, and the quick-add sheet
/// takes it from there.
struct ReceiptReadingView: View {
    let captures: [UIImage]
    let alreadyRectified: Bool
    var onRead: (ReceiptScan, [UIImage]) -> Void
    var onCancel: () -> Void
    var onRetry: () -> Void

    @State private var reader = ReceiptReader()
    @State private var revealed = 0
    @State private var sweep = false
    @State private var hasStarted = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(reader.failure == nil ? "Reading your receipt" : "Couldn't read that")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .contentTransition(.opacity)

                    Label("On this iPhone", systemImage: "lock.shield")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                }

                Spacer(minLength: 8)

                CircleGlyphButton(symbol: "xmark", size: 38, action: onCancel)
                    .accessibilityLabel("Close")
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 16)

            page
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 28)

            Group {
                if let failure = reader.failure {
                    failureCard(failure)
                } else {
                    stages
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)
            .frame(maxWidth: 520)
        }
        .background { CanvasBackground().ignoresSafeArea() }
        .animation(.smooth(duration: 0.3), value: reader.stage)
        .animation(.smooth(duration: 0.3), value: reader.failure)
        .onAppear {
            withAnimation(.linear(duration: 1.7).repeatForever(autoreverses: false)) { sweep = true }
        }
        .onChange(of: reader.stage) { _, _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .onChange(of: reader.failure) { _, failure in
            if failure != nil { UINotificationFeedbackGenerator().notificationOccurred(.error) }
        }
        .task {
            // Once. A task restarted by a layout pass must not start a second
            // read into the same reader — that's two sets of pages and marks.
            guard !hasStarted else { return }
            hasStarted = true
            let started = ContinuousClock.now
            await reader.read(captures, alreadyRectified: alreadyRectified)
            guard let scan = reader.result else { return }

            // Long enough to watch the lines come off the page and turn
            // colour; a fast phone shouldn't make the reading look skipped.
            let shown = ContinuousClock.now - started
            if shown < .seconds(2.2) { try? await Task.sleep(for: .seconds(2.2) - shown) }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled else { return }
            onRead(scan, reader.pages)
        }
        .task(id: reader.marks.count) {
            // Lines light up in reading order rather than all at once, fast
            // enough that even a long receipt finishes inside the sweep.
            let marks = reader.marks.count
            let step = max(1, marks / 45)
            while revealed < marks {
                try? await Task.sleep(for: .milliseconds(22))
                withAnimation(.easeOut(duration: 0.22)) { revealed = min(marks, revealed + step) }
            }
        }
    }

    // MARK: - Page

    @ViewBuilder
    private var page: some View {
        if let image = reader.pages.first {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .overlay { marks(on: 0) }
                .overlay { if isWorking { scanLine } }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppTheme.cardStroke.opacity(0.08))
                }
                .shadow(color: Color(red: 0.35, green: 0.2, blue: 0.1).opacity(0.18), radius: 22, y: 12)
                .overlay(alignment: .topTrailing) {
                    if reader.pages.count > 1 {
                        TagChip(title: "+\(reader.pages.count - 1) more", tint: AppTheme.accent, symbol: "doc.on.doc")
                            .background(AppTheme.card, in: .capsule)
                            .padding(10)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.card.opacity(0.7))
                .aspectRatio(0.62, contentMode: .fit)
                .overlay { scanLine }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay { ProgressView().tint(AppTheme.inkTertiary) }
        }
    }

    private var isWorking: Bool { reader.stage < .finished && reader.failure == nil }

    private func marks(on page: Int) -> some View {
        GeometryReader { proxy in
            ForEach(reader.marks.prefix(revealed).filter { $0.page == page }) { mark in
                markView(mark, in: proxy.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func markView(_ mark: ReceiptReader.Mark, in size: CGSize) -> some View {
        let tint = colour(mark.tone)
        let isPlain = mark.tone == .text
        let shape = RoundedRectangle(cornerRadius: 2.5, style: .continuous)

        return shape
            .fill(tint.opacity(isPlain ? 0.14 : 0.22))
            .overlay { shape.strokeBorder(tint.opacity(isPlain ? 0.35 : 0.7), lineWidth: 1) }
            .frame(width: max(6, mark.box.width * size.width + 6), height: max(6, mark.box.height * size.height + 4))
            .position(x: mark.box.midX * size.width, y: mark.box.midY * size.height)
            .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }

    private func colour(_ tone: ReceiptReader.Tone) -> Color {
        switch tone {
        case .text: AppTheme.inkTertiary
        case .item: AppTheme.accent
        case .charge: Palette.amber
        case .total: AppTheme.positive
        }
    }

    private var scanLine: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [AppTheme.accent.opacity(0), AppTheme.accent.opacity(0.22), AppTheme.accent.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 90)
            .overlay { Rectangle().fill(AppTheme.accent.opacity(0.85)).frame(height: 2) }
            .offset(y: sweep ? proxy.size.height : -90)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Stages

    private var stages: some View {
        VStack(spacing: 0) {
            stageRow(.straightening, title: "Straightening the paper", done: pagesDetail)
            Hairline(inset: 50)
            stageRow(.reading, title: "Reading the print", done: "\(reader.lineCount.pluralised("line"))")
            Hairline(inset: 50)
            stageRow(
                .understanding,
                title: reader.usesModel ? "Making sense of it" : "Working out items and tax",
                done: reader.result.map { "\($0.lines.count.pluralised("item"))" } ?? ""
            )
            Hairline(inset: 50)
            stageRow(
                .checking,
                title: reader.isTakingSecondLook ? "Taking a closer look" : "Checking it adds up",
                done: checkDetail
            )
        }
        .cardSurface(corner: 22)
    }

    private var pagesDetail: String {
        reader.pages.count > 1 ? "\(reader.pages.count) pages" : "Done"
    }

    private var checkDetail: String {
        guard let result = reader.result else { return "" }
        switch result.check {
        case .balanced, .rounded: return "Adds up"
        case .unaccounted: return "Needs a look"
        case .noTotal: return "No total printed"
        case .noItems: return "Total only"
        }
    }

    private func stageRow(_ stage: ReceiptReader.Stage, title: String, done: String) -> some View {
        let isDone = reader.stage > stage
        let isActive = reader.stage == stage

        return HStack(spacing: 12) {
            ZStack {
                if isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.positive)
                        .transition(.scale.combined(with: .opacity))
                } else if isActive {
                    ProgressView()
                        .controlSize(.small)
                        .tint(AppTheme.accent)
                } else {
                    Circle()
                        .strokeBorder(AppTheme.inkTertiary.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                        .frame(width: 18, height: 18)
                }
            }
            .frame(width: 24, height: 24)

            Text(title)
                .font(.system(size: 14.5, weight: isActive ? .semibold : .medium))
                .foregroundStyle(isDone || isActive ? AppTheme.ink : AppTheme.inkTertiary)
                .contentTransition(.opacity)

            Spacer(minLength: 6)

            if isDone, !done.isEmpty {
                Text(done)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Failure

    private func failureCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                SymbolBadge(symbol: "doc.text.magnifyingglass", tint: Palette.amber, size: 38)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            PrimaryButton(title: "Try another photo", systemImage: "arrow.counterclockwise", action: onRetry)
        }
        .padding(16)
        .cardSurface(corner: 22)
    }
}
