//
//  TripInviteSheet.swift
//  Equitrip
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import CoreMotion

/// Inviting someone to a trip.
///
/// The card is the point. Handing someone a join code usually means reading a
/// string of characters across a table, so this makes the card the thing you
/// turn toward them — it tilts with the phone, catches a highlight as it moves,
/// and carries the QR big enough to scan from across that table.
struct TripInviteSheet: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip

    @State private var motion = MotionTilt()
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 22) {
                    InviteCard(trip: trip, tilt: motion.tilt)
                        .padding(.top, 8)

                    codeRow
                    actions
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Invite to trip")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text("Anyone with this code joins \(trip.title)")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    private var codeRow: some View {
        Button {
            UIPasteboard.general.string = trip.inviteCode
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { copied = true }

            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeOut(duration: 0.25)) { copied = false }
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("JOIN CODE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(AppTheme.inkTertiary)

                    Text(trip.inviteCode)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppTheme.ink)
                }

                Spacer(minLength: 6)

                Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(copied ? AppTheme.positive : AppTheme.accent)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .cardSurface(corner: 20)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if let link = trip.inviteLink {
                ShareLink(item: link, message: Text("Join \(trip.title) on Equitrip")) {
                    HStack(spacing: 7) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Share invite")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.accent)
            }

            Text("They'll be added as a traveller. Nothing is charged to them until they're put on a booking.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.inkTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
    }
}

// MARK: - Card

/// The tilting card. Everything here is driven by one `tilt` vector so the
/// layers move together — background, sheen and content all respond to the
/// same motion at different depths, which is what sells it as a physical
/// object rather than an image that wobbles.
private struct InviteCard: View {
    let trip: Trip
    let tilt: CGSize

    private var qr: UIImage? {
        QRCode.make(from: trip.inviteLink?.absoluteString ?? trip.inviteCode)
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 11) {
                IconTile(symbol: trip.symbol, tint: trip.tint, size: 38, corner: 12)

                VStack(alignment: .leading, spacing: 1) {
                    Text(trip.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(trip.destination.isEmpty ? trip.dateRange : trip.destination)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)
            }
            // Nearest layer to the viewer, so it moves most.
            .offset(x: tilt.width * 8, y: tilt.height * 5)

            if let qr {
                Image(uiImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 168, height: 168)
                    .padding(12)
                    .background(.white, in: .rect(cornerRadius: 16, style: .continuous))
                    .offset(x: tilt.width * 4, y: tilt.height * 3)
            }

            VStack(spacing: 3) {
                Text(trip.inviteCode)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                Text("Scan or enter this code")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .offset(x: tilt.width * 6, y: tilt.height * 4)

            AvatarStack(travellers: trip.travellers, size: 26, max: 5)
                .offset(x: tilt.width * 3, y: tilt.height * 2)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background { backdrop }
        .overlay { sheen }
        .clipShape(.rect(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.16))
        }
        // Rotating about both axes with a little perspective is what makes it
        // read as a card being turned rather than a picture being skewed.
        .rotation3DEffect(.degrees(tilt.height * -7), axis: (x: 1, y: 0, z: 0), perspective: 0.55)
        .rotation3DEffect(.degrees(tilt.width * 9), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
        .shadow(color: .black.opacity(0.28), radius: 22, x: tilt.width * -10, y: 14)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: tilt)
    }

    private var backdrop: some View {
        LinearGradient(
            colors: [
                Color(red: 0.22, green: 0.19, blue: 0.62),
                Color(red: 0.10, green: 0.08, blue: 0.32)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            // A soft bloom that drifts opposite the tilt, like a light source
            // fixed in the room while the card turns under it.
            RadialGradient(
                colors: [trip.tint.opacity(0.55), .clear],
                center: .center,
                startRadius: 4,
                endRadius: 200
            )
            .offset(x: tilt.width * -46, y: tilt.height * -46)
            .blendMode(.plusLighter)
        }
    }

    /// The specular band. Travels across the face as the phone turns, which is
    /// the single strongest cue that the surface is catching light.
    private var sheen: some View {
        LinearGradient(
            colors: [.clear, .white.opacity(0.22), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .rotationEffect(.degrees(24))
        .offset(x: tilt.width * 150, y: tilt.height * 90)
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }
}

// MARK: - QR

enum QRCode {
    private static let context = CIContext()

    static func make(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        // Medium correction survives the rounded frame and a bit of glare
        // without making the modules so dense they blur when scaled up.
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Motion

/// Device attitude, smoothed and clamped into a small tilt vector.
@MainActor
@Observable
final class MotionTilt {
    private(set) var tilt: CGSize = .zero

    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1 / 30

        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }

            // Clamped well before the limits of comfortable wrist movement, so
            // the card reaches its full tilt from a small gesture instead of
            // needing the phone turned on its side.
            let roll = max(-1, min(1, motion.attitude.roll / 0.7))
            let pitch = max(-1, min(1, (motion.attitude.pitch - 0.6) / 0.7))

            // Low-pass filter: raw attitude is jittery enough to look broken.
            let smoothing = 0.15
            self.tilt = CGSize(
                width: self.tilt.width + (roll - self.tilt.width) * smoothing,
                height: self.tilt.height + (pitch - self.tilt.height) * smoothing
            )
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
