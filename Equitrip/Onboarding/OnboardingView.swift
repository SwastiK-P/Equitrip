//
//  OnboardingView.swift
//  Equitrip
//

import SwiftUI

struct OnboardingView: View {
    @State private var appeared = false

    var onSignIn: () -> Void = {}
    var onCreateAccount: () -> Void = {}

    var body: some View {
        ZStack {
            CanvasBackground()

            // Fixed layout — no scrolling. Spacers absorb the slack, and the
            // compact branch keeps it whole on shorter devices.
            GeometryReader { geo in
                let compact = geo.size.height < 780

                VStack(spacing: 0) {
                    Spacer(minLength: compact ? 12 : 24)

                    OnboardingHero(appeared: appeared)
                        .frame(height: compact ? 168 : 190)

                    // Fixed, deliberately tight — the remaining slack goes to
                    // the flexible spacers, which pushes the deck down the page.
                    headline
                        .padding(.top, compact ? 10 : 14)

                    Spacer(minLength: compact ? 14 : 24)

                    features

                    Spacer(minLength: compact ? 14 : 24)

                    actions
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { appeared = true }
        }
    }

    // MARK: - Headline

    private var headline: some View {
        VStack(spacing: 10) {
            Text("Split the trip,\nnot the friendship.")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text("Every booking, expense and balance in one shared plan.")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 14)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.28), value: appeared)
    }

    // MARK: - Feature cards

    private var features: some View {
        VStack(spacing: 12) {
            ForEach(Array(OnboardingFeature.all.enumerated()), id: \.element.id) { index, feature in
                FeatureCard(feature: feature)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 22)
                    .animation(
                        .spring(response: 0.62, dampingFraction: 0.82)
                        .delay(0.38 + Double(index) * 0.08),
                        value: appeared
                    )
            }
        }
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 6) {
            PrimaryButton(title: "Sign in", action: onSignIn)

            TextButton(title: "New to Equitrip?", emphasis: "Create account", action: onCreateAccount)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 26)
        .animation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.6), value: appeared)
    }
}

// MARK: - Feature card

private struct FeatureCard: View {
    @Environment(\.colorScheme) private var scheme
    let feature: OnboardingFeature

    var body: some View {
        HStack(spacing: 14) {
            IconTile(symbol: feature.symbol)

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(feature.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppTheme.cardStroke.opacity(scheme == .dark ? 0.08 : 0.04))
        }
        .shadow(color: AppTheme.softShadow(scheme), radius: 14, y: 6)
    }
}

// MARK: - Model

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let subtitle: String

    static let all: [OnboardingFeature] = [
        .init(
            symbol: "map.fill",
            title: "One itinerary, everyone in sync.",
            subtitle: "Flights, stays and activities in one plan."
        ),
        .init(
            symbol: "arrow.triangle.2.circlepath",
            title: "Shares recalculate themselves.",
            subtitle: "Balances update when plans change."
        ),
        .init(
            symbol: "checkmark",
            title: "Settle with proof, not promises.",
            subtitle: "You mark a payment, they confirm it."
        )
    ]
}

#Preview("Light") {
    OnboardingView()
}

#Preview("Dark") {
    OnboardingView()
        .preferredColorScheme(.dark)
}
