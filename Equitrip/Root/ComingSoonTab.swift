//
//  ComingSoonTab.swift
//  Equitrip
//

import SwiftUI

/// Placeholder for the three tabs still to be built. Deliberately states what
/// will live there rather than showing a fake empty state, so the shell reads
/// as unfinished-on-purpose instead of broken.
struct ComingSoonTab: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    let points: [String]

    @State private var appeared = false

    var body: some View {
        ZStack {
            CanvasBackground()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 18) {
                    IconTile(symbol: symbol, tint: tint, size: 62, corner: 20)
                        .staggered(0, appeared)

                    VStack(spacing: 7) {
                        Text(title)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)

                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.inkSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .staggered(1, appeared)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                            HStack(alignment: .top, spacing: 11) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 5))
                                    .foregroundStyle(tint)
                                    .padding(.top, 6.5)

                                Text(point)
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.inkSecondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)

                            if index < points.count - 1 {
                                Hairline(inset: 16)
                            }
                        }
                    }
                    .cardSurface(corner: 22)
                    .staggered(2, appeared)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 0)

                TagChip(title: "Coming next", tint: AppTheme.inkTertiary, symbol: "hammer.fill")
                    .padding(.bottom, 20)
                    .staggered(3, appeared)
            }
        }
        .onAppear {
            appeared = true
        }
    }
}

#Preview {
    ComingSoonTab(
        title: "Itinerary",
        subtitle: "The master plan, day by day.",
        symbol: "map.fill",
        tint: AppTheme.accent,
        points: [
            "Transport, stays and activities on one timeline",
            "Pick exactly who's on each booking",
            "Switch between the group plan and yours"
        ]
    )
}
