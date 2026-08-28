//
//  TripImportStage.swift
//  Equitrip
//

import SwiftUI
import UniformTypeIdentifiers

/// Picks a PDF and watches the document being read.
///
/// The screen has two postures and moves between them once. While there is
/// nothing to show, the document sits in the middle of the screen being
/// scanned — it is the only thing happening, so it gets the whole screen. The
/// moment the first real fact lands, it docks to the top and the trip builds
/// underneath it, day by day.
///
/// That move is the honest shape of what's happening: the document stops being
/// the subject and becomes the source. Streaming the days in as they finish
/// isn't decoration either — it's the only way to show a read that takes half a
/// minute, and it lets someone spot a bad day early instead of at the end.
struct TripImportStage: View {
    var onExtracted: (TripDraft) -> Void
    var onManualInstead: () -> Void

    @State private var extractor = TripExtractor()
    @State private var phase: Phase = .picking
    @State private var fileName: String?
    @State private var showPicker = false
    @State private var failure: String?
    @State private var failureRecovery: String?
    @State private var scanning = false

    private enum Phase {
        case picking, reading, done, failed
    }

    /// The document leaves the middle of the screen as soon as there is
    /// something true to put underneath it.
    private var docked: Bool {
        phase == .done || extractor.progress.hasSummary || !extractor.progress.days.isEmpty
    }

    private var days: [PlannedDay] {
        extractor.progress.days.sorted { $0.date < $1.date }
    }

    var body: some View {
        Group {
            switch phase {
            case .picking:
                picker
            case .reading, .done:
                reading
            case .failed:
                failureState
            }
        }
        .safeAreaInset(edge: .bottom) {
            if phase == .done { continueBar }
        }
        .fileImporter(
            isPresented: $showPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handle(result)
        }
        .onAppear {
            // Straight to the file browser — the previous screen already
            // committed to importing, so a second "pick a file" tap is a stall.
            if phase == .picking { showPicker = true }
        }
    }

    // MARK: - Picking

    private var picker: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 40)

            IconTile(symbol: "doc.text.viewfinder", tint: AppTheme.accent, size: 58, corner: 19)

            VStack(spacing: 5) {
                Text("Choose a PDF")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text("A booking confirmation, e-ticket or agent itinerary.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .multilineTextAlignment(.center)
            }

            Button("Browse files") { showPicker = true }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.accent)
                .padding(.top, 4)

            Button("Add it manually instead", action: onManualInstead)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.inkSecondary)
                .buttonStyle(.plain)
                .padding(.top, 2)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: - Reading

    private var reading: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 18) {
                    // Collapsing this is the whole move: the card rises from
                    // the middle of the screen to the top of a list.
                    Spacer(minLength: 0)
                        .frame(height: docked ? 0 : nil)

                    documentCard

                    if docked {
                        if extractor.progress.hasSummary {
                            summaryCard
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        ForEach(days) { day in
                            daySection(day)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .opacity
                                    )
                                )
                        }

                        if phase == .done, extractor.progress.days.isEmpty {
                            emptyResult
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(minHeight: proxy.size.height, alignment: .top)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .animation(.spring(response: 0.58, dampingFraction: 0.85), value: docked)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: extractor.progress.itemCount)
        .animation(.easeOut(duration: 0.25), value: extractor.progress.title)
    }

    /// One card in two postures. `AnyLayout` is what lets it be a hero and a
    /// list row without being two views — SwiftUI interpolates the layout
    /// change, so the icon and the filename travel rather than cross-fading.
    private var documentCard: some View {
        let layout = docked
            ? AnyLayout(HStackLayout(alignment: .center, spacing: 13))
            : AnyLayout(VStackLayout(spacing: 14))

        return layout {
            documentGlyph

            VStack(alignment: docked ? .leading : .center, spacing: docked ? 2 : 5) {
                Text(fileName ?? "Document")
                    .font(.system(size: docked ? 14.5 : 17, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 5) {
                    if phase == .reading {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(AppTheme.accent)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.positive)
                    }

                    Text(statusLine)
                        .font(.system(size: docked ? 12 : 13.5))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .contentTransition(.opacity)
                }
            }
            .frame(maxWidth: docked ? .infinity : nil, alignment: docked ? .leading : .center)

            if !docked { readingBar }
        }
        .padding(docked ? 14 : 24)
        .frame(maxWidth: .infinity)
        .cardSurface(corner: docked ? 20 : 26)
    }

    /// A page with a light sweeping down it. Slow on purpose — a fast shimmer
    /// reads as a loading skeleton, and this is a thing being read.
    private var documentGlyph: some View {
        ZStack {
            RoundedRectangle(cornerRadius: docked ? 11 : 20, style: .continuous)
                .fill(AppTheme.danger.opacity(0.14))
                .frame(width: docked ? 44 : 96, height: docked ? 44 : 96)

            Image(systemName: "doc.fill")
                .font(.system(size: docked ? 18 : 40, weight: .semibold))
                .foregroundStyle(AppTheme.danger)

            if phase == .reading {
                RoundedRectangle(cornerRadius: docked ? 11 : 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.55), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: docked ? 44 : 96, height: docked ? 22 : 48)
                    .offset(y: scanning ? (docked ? 26 : 58) : (docked ? -26 : -58))
                    .blur(radius: 6)
                    .mask {
                        RoundedRectangle(cornerRadius: docked ? 11 : 20, style: .continuous)
                            .frame(width: docked ? 44 : 96, height: docked ? 44 : 96)
                    }
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                scanning = true
            }
        }
    }

    /// Days finished, out of days found. A determinate bar because the count is
    /// genuinely known — the document was cut into days before any of this
    /// started, so there is no excuse for a barber's pole.
    private var readingBar: some View {
        VStack(spacing: 7) {
            if case .reading(let done, let total) = extractor.progress.stage, total > 0 {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.cardStroke.opacity(0.12))
                        Capsule()
                            .fill(AppTheme.accent)
                            .frame(width: proxy.size.width * (Double(done) / Double(total)))
                    }
                }
                .frame(height: 4)
                .animation(.spring(response: 0.5, dampingFraction: 0.9), value: done)
            }
        }
        .frame(maxWidth: 200)
        .padding(.top, 2)
    }

    private var statusLine: String {
        switch phase {
        case .done:
            let count = extractor.progress.itemCount
            let how = extractor.usedFallback ? "found by pattern" : "read by Apple Intelligence"
            return "\(count.pluralised("booking")) \(how)"
        default:
            let found = extractor.progress.itemCount
            let caption = extractor.progress.stage.caption
            return found == 0 ? caption : "\(caption) · \(found) found"
        }
    }

    /// The trip-level facts, filling in as they're established.
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !extractor.progress.title.isEmpty {
                LiveField(label: "Trip", value: extractor.progress.title)
            }
            if !extractor.progress.destination.isEmpty {
                LiveField(label: "Destination", value: extractor.progress.destination)
            }
            if extractor.progress.travellerCount > 0 {
                LiveField(
                    label: "Travellers",
                    value: travellerLine,
                    // Said out loud, because the next screen asks about it and
                    // an unexplained question is a worse question.
                    footnote: extractor.progress.travellerNames.isEmpty
                        ? "The document doesn't name them — you'll add them next"
                        : nil
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface(corner: 22)
    }

    private var travellerLine: String {
        let names = extractor.progress.travellerNames
        guard names.isEmpty else { return names.joined(separator: ", ") }
        return extractor.progress.travellerCount.pluralised("person", "people")
    }

    private func daySection(_ day: PlannedDay) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(DateFormatter.cached("EEE d MMM").string(from: day.date).uppercased())
                    .font(.system(size: 10.5, weight: .bold))
                    .tracking(0.9)
                    .foregroundStyle(AppTheme.inkTertiary)

                if !day.heading.isEmpty {
                    Text(day.heading)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary.opacity(0.8))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.leading, 2)

            VStack(spacing: 0) {
                ForEach(Array(day.items.enumerated()), id: \.element.id) { index, item in
                    ExtractedRow(item: item, currencyCode: extractor.progress.currencyCode)

                    if index < day.items.count - 1 { Hairline(inset: 58) }
                }
            }
            .cardSurface(corner: 18, shadow: 7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyResult: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(AppTheme.inkTertiary)

            Text("Nothing recognisable in there")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            Text("The document didn't have anything that looks like a booking. You can still set the trip up by hand.")
                .font(.system(size: 13.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .multilineTextAlignment(.center)

            Button("Add it manually", action: onManualInstead)
                .buttonStyle(.glassProminent)
                .tint(AppTheme.accent)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Failure

    private var failureState: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 30)

            IconTile(symbol: "exclamationmark.triangle.fill", tint: AppTheme.danger, size: 52, corner: 17)

            VStack(spacing: 6) {
                Text(failure ?? "That didn't work")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)

                if let failureRecovery {
                    Text(failureRecovery)
                        .font(.system(size: 13.5))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            HStack(spacing: 10) {
                Button("Try another file") {
                    phase = .picking
                    showPicker = true
                }
                .buttonStyle(.glass)

                Button("Add manually", action: onManualInstead)
                    .buttonStyle(.glassProminent)
                    .tint(AppTheme.accent)
            }
            .padding(.top, 6)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
    }

    // MARK: - Continue

    private var continueBar: some View {
        Button {
            let draft = TripDraft.from(
                extractor.progress,
                fileName: fileName,
                usedFallback: extractor.usedFallback
            )
            onExtracted(draft)
        } label: {
            HStack(spacing: 7) {
                Text("Review \(extractor.progress.itemCount.pluralised("booking"))")
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.glassProminent)
        .tint(AppTheme.accent)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .disabled(extractor.progress.itemCount == 0)
        .opacity(extractor.progress.itemCount == 0 ? 0 : 1)
    }

    // MARK: - Work

    private func handle(_ result: Result<[URL], Error>) {
        switch result {
        case .failure:
            // Cancelling the picker isn't an error — it means "take me back".
            if phase == .picking { onManualInstead() }

        case .success(let urls):
            guard let url = urls.first else { return }
            fileName = url.lastPathComponent
            phase = .reading

            Task {
                do {
                    let text = try PDFReader.text(at: url)
                    await extractor.extract(from: text)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        phase = .done
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } catch let error as PDFReader.ReadError {
                    failure = error.errorDescription
                    failureRecovery = error.recovery
                    phase = .failed
                } catch {
                    failure = "That file couldn't be read."
                    failureRecovery = "Try another file, or add the trip manually."
                    phase = .failed
                }
            }
        }
    }
}

// MARK: - Rows

/// One trip-level fact, revealed as it's established.
private struct LiveField: View {
    let label: String
    let value: String
    var footnote: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
                .frame(width: 84, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)

                if let footnote {
                    Text(footnote)
                        .font(.system(size: 11.5))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
    }
}

/// One booking as it lands. Compact on purpose — this is a confirmation the
/// read is going well, not the place to edit anything.
private struct ExtractedRow: View {
    let item: PlannedItem
    let currencyCode: String

    var body: some View {
        HStack(spacing: 12) {
            Text(item.clockText.isEmpty ? "—" : item.clockText)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.inkTertiary)
                .frame(width: 38, alignment: .leading)
                .monospacedDigit()

            SymbolBadge(
                symbol: item.kind.asItineraryKind.symbol,
                tint: item.kind.asItineraryKind.tint,
                size: 30
            )

            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                if !item.detail.isEmpty {
                    Text(item.detail)
                        .font(.system(size: 11.5))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .lineLimit(1)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            if item.amount > 0 {
                Text(Money.format(item.amount, code: currencyCode.isEmpty ? "INR" : currencyCode))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize()
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
    }
}
