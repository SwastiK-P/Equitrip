//
//  ScenarioPresetGrid.swift
//  Equitrip
//

import SwiftUI

/// The first choice in a what-if: which weather to play out.
///
/// All six fit on screen in a grid — the strip of cards it replaced showed
/// two and a half and scrolled sideways for the rest, so "Cyclone" was the
/// option most people never saw. The chosen one's symbol turns multicolor —
/// the one place colour marks a choice rather than a risk.
struct ScenarioPresetGrid: View {
    @Binding var scenario: TwinScenario

    private static let presets: [TwinScenario.Preset] = [.monsoonBurst, .thunderstorm, .cyclone, .flashFlood, .heatwave]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(Self.presets) { preset in
                    tile(preset.label, symbol: preset.symbol, isOn: scenario.preset == preset) {
                        apply(preset.scenario)
                    }
                }
                tile("Your own", symbol: "slider.horizontal.3", isOn: scenario.preset == nil) {
                    // A clean slate: the forecast as it is, for the dials below to build on.
                    guard scenario.preset != nil else { return }
                    apply(TwinScenario())
                }
            }
        }
    }

    /// Keeps where and when the person already chose; a preset only sets how
    /// bad the weather is.
    private func apply(_ next: TwinScenario) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        var next = next
        next.targetDay = scenario.targetDay
        next.center = scenario.center
        next.radiusKm = scenario.radiusKm
        if next.isLive {
            next.startHour = scenario.startHour
            next.durationHours = scenario.durationHours
        }
        // Not animated: a spring over the whole what-if panel, on top of the
        // sky redrawing and the simulation re-running, is what made switching
        // weather stutter. The dials animate their own arcs.
        scenario = next
    }

    private func tile(_ title: String, symbol: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .medium))
                    .symbolRenderingMode(isOn ? .multicolor : .hierarchical)
                    .foregroundStyle(isOn ? AppTheme.ctaLabel : AppTheme.ink)
                    .frame(height: 22)
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isOn ? AppTheme.ctaLabel : AppTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isOn ? AnyShapeStyle(AppTheme.cta) : AnyShapeStyle(AppTheme.card))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.cardStroke.opacity(isOn ? 0 : 0.07))
            }
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
