//
//  QRScannerView.swift
//  Equitrip
//

import AVFoundation
import SwiftUI
import VisionKit
import Vision

/// Live QR scanning through VisionKit's data scanner.
///
/// Reports each distinct payload once — the scanner fires continuously while a
/// code is in frame, and without the guard a single QR would trigger the join
/// flow dozens of times a second.
///
/// VisionKit's own highlight and guidance are both switched off: the overlay
/// in `QRScanScreen` does that job, and having the system draw a second yellow
/// box inside our aperture — with its own "Slow Down" label — was the reason
/// the screen looked like two apps arguing.
struct QRScannerView: UIViewControllerRepresentable {
    /// The payload, and the four corners of the symbol in this view's
    /// coordinate space — which is what lets the burst draw the code exactly
    /// where the camera found it, at the angle it found it.
    var onScan: (String, QuadCorners) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: false,
            isGuidanceEnabled: false,
            isHighlightingEnabled: false
        )
        controller.delegate = context.coordinator
        controller.view.backgroundColor = .black
        return controller
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        guard !controller.isScanning else { return }
        try? controller.startScanning()
    }

    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: Coordinator) {
        controller.stopScanning()
        Torch.set(false)
    }

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScan: (String, QuadCorners) -> Void
        private var handled: String?

        init(onScan: @escaping (String, QuadCorners) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(_ scanner: DataScannerViewController, didAdd items: [RecognizedItem], allItems: [RecognizedItem]) {
            report(items)
        }

        func dataScanner(_ scanner: DataScannerViewController, didUpdate items: [RecognizedItem], allItems: [RecognizedItem]) {
            report(items)
        }

        private func report(_ items: [RecognizedItem]) {
            for item in items {
                guard case .barcode(let barcode) = item,
                      let payload = barcode.payloadStringValue,
                      payload != handled else { continue }
                handled = payload

                let bounds = barcode.bounds
                onScan(
                    payload,
                    QuadCorners(
                        topLeft: bounds.topLeft,
                        topRight: bounds.topRight,
                        bottomRight: bounds.bottomRight,
                        bottomLeft: bounds.bottomLeft
                    )
                )
            }
        }
    }
}

// MARK: - Torch

/// The back camera's lamp.
///
/// `DataScannerViewController` owns the capture session and doesn't expose the
/// torch, but the device object is shared — locking it for configuration works
/// perfectly well while somebody else is streaming from it, which is what lets
/// the scanner have a working torch button at all.
enum Torch {
    static var isAvailable: Bool {
        AVCaptureDevice.default(for: .video)?.hasTorch ?? false
    }

    static func set(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        guard (try? device.lockForConfiguration()) != nil else { return }
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }
}

// MARK: - Scan screen

/// The camera, framed.
///
/// A raw `DataScannerViewController` fills the screen with a live feed and no
/// indication of where to point it, which is why the old version needed a
/// caption explaining what to do. This puts an aperture on it: everything
/// outside the square is dimmed and the corners are bracketed, breathing
/// slightly so the screen reads as actively looking rather than merely being
/// a camera that happens to be on.
///
/// The whole thing is one state machine — `hunting`, `found`, `working` — so
/// the moment a code lands the brackets snap in, and the
/// frame goes green under a checkmark. Nothing about that is decoration: the
/// gap between "the camera saw it" and "the trip loaded" is a network call,
/// and without a state for it people scan the same code three more times.
struct QRScanScreen: View {
    /// Called with whatever the QR contained. Returns whether it was ours —
    /// a `false` puts the frame back to hunting after saying so, because the
    /// world is full of QR codes and pointing the camera at a restaurant menu
    /// shouldn't leave the scanner locked on it forever.
    var onScan: (String) -> Bool
    var onCancel: () -> Void

    /// Fired when the burst has filled the screen with white. The presenter
    /// swaps to whatever comes next behind that white and fades it off, so the
    /// camera never visibly disappears — the next screen is revealed out of
    /// the flash rather than sliding in over a frozen viewfinder.
    var onWhiteout: () -> Void = {}

    /// Set by the presenter while it resolves the code, so the frame can hold
    /// its "got it" state instead of dropping back to hunting.
    var isResolving: Bool = false

    @State private var phase: Phase = .hunting
    @State private var breathe = false
    @State private var torchOn = false
    /// The code that was just read, and where on screen the camera found it.
    /// Non-nil means the burst is playing and the viewfinder chrome has handed
    /// over to it.
    @State private var burst: Burst?

    private struct Burst: Equatable {
        let matrix: [[Bool]]
        let found: QuadCorners
    }

    private enum Phase: Equatable { case hunting, found, rejected }

    private var isLocked: Bool { phase == .found || isResolving }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width * 0.74, 300)
            let centre = CGPoint(x: proxy.size.width / 2, y: proxy.size.height * 0.42)
            let aperture = CGRect(
                x: centre.x - side / 2,
                y: centre.y - side / 2,
                width: side,
                height: side
            )

            ZStack {
                Color.black

                // Deliberately unscaled and unclipped. The scanner reports
                // the code's corners in this view's own coordinates, and the
                // burst draws on top of it in the same space — any transform
                // here and the white code lands somewhere the real one isn't.
                QRScannerView(onScan: handle)

                Group {
                    scrim(aperture: aperture, in: proxy.size)
                    frame(in: aperture)
                    caption(below: aperture, in: proxy.size)
                }
                // The burst paints its own veil and its own code, so the
                // reticle steps out of the way rather than sitting under it.
                .opacity(burst == nil ? 1 : 0)
                .animation(.easeOut(duration: 0.16), value: burst == nil)

                if let burst {
                    QRBurst(
                        matrix: burst.matrix,
                        found: burst.found,
                        // Settles smaller than the aperture it was hunting in.
                        // Shrinking on the way to the middle reads as the code
                        // being picked up and carried off, where landing at
                        // the same size reads as it merely sliding across.
                        target: aperture.insetBy(
                            dx: aperture.width * 0.21,
                            dy: aperture.height * 0.21
                        ),
                        onWhiteout: onWhiteout
                    )
                    .transition(.identity)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        // Its own bar rather than the join flow's. That one is dark ink on
        // the peach canvas and disappears completely against a camera feed,
        // and a full-bleed camera shouldn't be pushed down by a safe-area
        // inset it doesn't want.
        .overlay(alignment: .top) {
            topBar
                .opacity(burst == nil ? 1 : 0)
                .allowsHitTesting(burst == nil)
                .animation(.easeOut(duration: 0.16), value: burst == nil)
        }
        .onAppear {
            // Started here rather than on the first scan: spinning the haptic
            // engine up costs tens of milliseconds, which is most of the first
            // beat of the burst.
            BurstHaptics.prepare()

            withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
        .onDisappear { setTorch(false) }
        .statusBarHidden()
    }

    private func handle(_ payload: String, corners: QuadCorners) {
        guard !isLocked, phase != .rejected else { return }

        guard onScan(payload) else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { phase = .rejected }

            Task {
                try? await Task.sleep(for: .seconds(1.6))
                withAnimation(.easeOut(duration: 0.3)) { phase = .hunting }
            }
            return
        }

        phase = .found

        // The particles are the code's own modules, re-encoded from what was
        // just read. A payload we somehow can't re-encode still has to hand
        // over, so it gets the flash on a timer instead of a burst. "H"
        // because that's what the invite card (`InviteQRCode`) encodes at.
        let modules = QRCode.matrix(from: payload, correction: "H")
        guard !modules.isEmpty else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            Task {
                try? await Task.sleep(for: .milliseconds(360))
                onWhiteout()
            }
            return
        }

        burst = Burst(matrix: modules, found: corners)
    }

    // MARK: - Scrim

    /// Everything but the square, dimmed. Drawn as one even-odd path rather
    /// than four rectangles around a hole, so the corner radius of the opening
    /// is a real radius and not four mitred guesses.
    private func scrim(aperture: CGRect, in size: CGSize) -> some View {
        ApertureMask(aperture: aperture, corner: 34)
            .fill(
                Color.black.opacity(isLocked ? 0.72 : 0.55),
                style: FillStyle(eoFill: true)
            )
            .animation(.easeOut(duration: 0.3), value: isLocked)
            .allowsHitTesting(false)
    }

    // MARK: - Frame

    private func frame(in aperture: CGRect) -> some View {
        ZStack {
            // The opening's own hairline, so the square still reads as a
            // square against a bright wall where the scrim has little to do.
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)

            brackets

            if isLocked {
                foundMark
            }
        }
        .frame(width: aperture.width, height: aperture.height)
        .position(x: aperture.midX, y: aperture.midY)
        .allowsHitTesting(false)
    }

    private var accentNow: Color {
        if isLocked { return AppTheme.positive }
        if phase == .rejected { return Palette.amber }
        return .white
    }

    /// Four corner brackets. They breathe slightly while hunting and snap
    /// tight the instant a code lands — the size change is what makes the
    /// lock-on read as a lock-on rather than a colour swap.
    private var brackets: some View {
        GeometryReader { proxy in
            let length = min(proxy.size.width, proxy.size.height) * 0.17

            ZStack {
                ForEach(Corner.allCases, id: \.self) { position in
                    BracketShape(corner: position, length: length, radius: 30)
                        .stroke(accentNow, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                }
            }
            .shadow(color: accentNow.opacity(0.55), radius: isLocked ? 14 : 8)
            .padding(isLocked ? 10 : (breathe ? 2 : 6))
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.7), value: isLocked)
        .animation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true), value: breathe)
    }

    private var foundMark: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 54, weight: .semibold))
            .foregroundStyle(.white, AppTheme.positive)
            .transition(.scale(scale: 0.5).combined(with: .opacity))
    }

    // MARK: - Caption

    private func caption(below aperture: CGRect, in size: CGSize) -> some View {
        VStack(spacing: 7) {
            Text(captionTitle)
                .font(.system(size: 15.5, weight: .semibold))
                .foregroundStyle(.white)
                .contentTransition(.opacity)

            Text(captionDetail)
                .font(.system(size: 12.5))
                .foregroundStyle(.white.opacity(0.62))
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 30)
        .position(x: size.width / 2, y: aperture.maxY + 52)
        .animation(.easeOut(duration: 0.25), value: isLocked)
        .animation(.easeOut(duration: 0.25), value: phase)
        .allowsHitTesting(false)
    }

    private var captionTitle: String {
        if isLocked { return "Got it" }
        if phase == .rejected { return "Not an Equitrip invite" }
        return "Point at the invite card's QR"
    }

    private var captionDetail: String {
        if isLocked { return "Finding the trip…" }
        if phase == .rejected { return "That code belongs to something else." }
        return "It scans on its own — no button to press."
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.ultraThinMaterial, in: .circle)
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Back")

            Spacer(minLength: 8)

            torchButton
        }
        .padding(.horizontal, 20)
        .padding(.top, ScreenInsets.top + 4)
    }

    @ViewBuilder
    private var torchButton: some View {
        if Torch.isAvailable {
            Button {
                setTorch(!torchOn)
            } label: {
                Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(torchOn ? .black : .white)
                    .frame(width: 42, height: 42)
                    .background(torchOn ? AnyShapeStyle(.white) : AnyShapeStyle(.ultraThinMaterial), in: .circle)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(torchOn ? "Turn the light off" : "Turn the light on")
        }
    }

    private func setTorch(_ on: Bool) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        torchOn = on
        Torch.set(on)
    }
}

// MARK: - Aperture

/// The full frame with a rounded square punched out of it. Filled even-odd.
private struct ApertureMask: Shape {
    var aperture: CGRect
    var corner: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addPath(Path(roundedRect: aperture, cornerRadius: corner, style: .continuous))
        return path
    }
}
