//
//  EquiAgentHUD.swift
//  Equitrip
//

import SwiftUI

/// The capsule under the Dynamic Island while Equi works: what the job is,
/// the step it's on, how far along, and the way to stop it.
///
/// Up top rather than at the bottom, where every screen keeps the buttons the
/// cursor is heading for. The step line pushes up as each new one arrives, so
/// the capsule reads as a running log without growing into one.
struct EquiAgentHUD: View {
    var agent: EquiAgent

    var body: some View {
        HStack(spacing: 11) {
            EquiAgentBadge(mood: agent.mood, progress: agent.progress, size: 36)

            VStack(alignment: .leading, spacing: 1) {
                Text(eyebrow)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
                    .contentTransition(.opacity)

                // The question itself is on the card below; saying it twice
                // reads as two things asking.
                Text(agent.mood == .asking ? "Waiting for your answer" : agent.step.text)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .id(agent.mood == .asking ? "asking" : agent.step.text)
                    .transition(.asymmetric(
                        insertion: .push(from: .bottom).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
            }
            .clipped()

            Spacer(minLength: 4)

            if agent.mood == .working || agent.mood == .asking {
                Button { agent.stop() } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.ink.opacity(0.07), in: .circle)
                        .contentShape(.circle)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Stop Equi")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.leading, 7)
        .padding(.trailing, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: 400)
        .glassEffect(.regular.tint(AppTheme.accent.opacity(0.05)), in: .capsule)
        .overlay { Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 0.75) }
        .shadow(color: AppTheme.accent.opacity(0.18), radius: 18, y: 6)
        .animation(.spring(response: 0.38, dampingFraction: 0.84), value: agent.step.text)
        .animation(.spring(response: 0.38, dampingFraction: 0.84), value: agent.mood)
    }

    private var eyebrow: String {
        let head: String = switch agent.mood {
        case .working, .asking: agent.title
        case .done: agent.doneTitle
        case .stopped: "Stopped"
        case .failed: "Couldn't finish"
        }
        return agent.context.isEmpty ? head : "\(head) · \(agent.context)"
    }
}

/// Equi's face with the run's progress drawn round it — the HUD's lead and
/// the question card's.
struct EquiAgentBadge: View {
    var mood: EquiAgent.Mood
    var progress: Double
    var size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.accent.opacity(0.12), lineWidth: 2.5)

            Circle()
                .trim(from: 0, to: max(0.04, progress))
                .stroke(
                    AngularGradient(colors: [AppTheme.accent, Palette.violet, AppTheme.accent], center: .center),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(mood == .done ? 0 : 1)

            Circle()
                .fill(LinearGradient(colors: faceColors, startPoint: .top, endPoint: .bottom))
                .padding(4.5)

            Group {
                switch mood {
                case .done:
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.34, weight: .bold))
                case .failed:
                    Image(systemName: "exclamationmark")
                        .font(.system(size: size * 0.34, weight: .bold))
                case .stopped:
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: size * 0.3, weight: .semibold))
                case .asking:
                    Image(systemName: "questionmark")
                        .font(.system(size: size * 0.34, weight: .bold))
                case .working:
                    Image("Equi")
                        .font(.system(size: size * 0.34, weight: .semibold))
                        .symbolEffect(.breathe, isActive: true)
                }
            }
            .foregroundStyle(.white)
            .contentTransition(.symbolEffect(.replace))
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: mood)
    }

    private var faceColors: [Color] {
        switch mood {
        case .working: [AppTheme.accent, AppTheme.accentDeep]
        case .asking: [Palette.violet, Palette.violetDeep]
        case .done: [Palette.violet, AppTheme.accentDeep]
        case .failed: [Palette.glowRed, AppTheme.danger]
        case .stopped: [AppTheme.inkTertiary, AppTheme.inkSecondary]
        }
    }
}
