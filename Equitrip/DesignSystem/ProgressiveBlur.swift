//
//  ProgressiveBlur.swift
//  Equitrip
//

import SwiftUI

// MARK: - Progressive blur

/// A blur that ramps in across a strip rather than switching on at a line.
///
/// Three materials, each masked to start further down than the last. A single
/// blurred layer with a gradient mask fades the blur's *opacity*, which reads
/// as a haze appearing over a sharp picture; stacking them means the radius
/// itself climbs, which is what makes it look like the image is going out of
/// focus toward the edge. That's the difference between text that sits on a
/// photograph and text that sits in it.
///
/// Cheap, and deliberately so: materials sample the backdrop, so the content
/// underneath is drawn once. The alternative — rendering the image three more
/// times at increasing blur radii — is the usual way to do this and costs
/// three more decodes of a full-bleed photograph.
struct ProgressiveBlur: View {
    /// Which end is fully blurred.
    var edge: VerticalEdge = .bottom
    /// Where the ramp begins, as a fraction of the height from the other edge.
    /// The default blurs across the whole span; a banner wants the picture left
    /// alone until the text needs it, so it passes something like 0.45.
    var begins: Double = 0
    /// How much of the darkening scrim rides along with it. Zero for a pure
    /// defocus; the default carries enough to keep white text legible over a
    /// bright sky.
    var scrim: Double = 0.42

    var body: some View {
        ZStack {
            layer(.ultraThinMaterial, clearAt: 0.00, solidAt: 0.45)
            layer(.thinMaterial, clearAt: 0.28, solidAt: 0.70)
            layer(.regularMaterial, clearAt: 0.52, solidAt: 0.92)
        }
        // Materials take their tone from the appearance, and Equitrip is a
        // light-mode app — so left alone these render as pale grey, which is
        // the worst possible ground for the white type they exist to support.
        // Forcing dark here makes the blurred band read as smoked glass over
        // the photograph rather than as fog on top of it, and it's the reason
        // the picture's colour still comes through at the bottom.
        .environment(\.colorScheme, .dark)
        .overlay {
            if scrim > 0 {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: place(0)),
                        .init(color: .black.opacity(scrim * 0.45), location: place(0.55)),
                        .init(color: .black.opacity(scrim), location: 1)
                    ],
                    startPoint: start,
                    endPoint: end
                )
            }
        }
        .allowsHitTesting(false)
    }

    private var start: UnitPoint { edge == .bottom ? .top : .bottom }
    private var end: UnitPoint { edge == .bottom ? .bottom : .top }

    /// Squeezes a 0…1 stop into the span the ramp is allowed to occupy.
    private func place(_ location: Double) -> Double {
        begins + location * (1 - begins)
    }

    private func layer(_ material: Material, clearAt: Double, solidAt: Double) -> some View {
        Rectangle()
            .fill(material)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: place(clearAt)),
                        .init(color: .black, location: place(solidAt))
                    ],
                    startPoint: start,
                    endPoint: end
                )
            }
    }
}
