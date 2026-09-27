//
//  EquiAgentLiveActivity.swift
//  EquitripWidgets
//

import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Equi's job, live on the Lock Screen and in the Dynamic Island, for when
/// the app is out of sight: each step as it lands, the question when it
/// needs you — answerable right there — and what it came to, which stays in
/// the island until the app is opened again.
///
/// Night ink and purple rather than the app's peach. A Live Activity sits
/// among notifications on a photograph, where the one light surface reads as
/// a banner; dark lets Equi's purple glow the way the edge light does in the
/// app, so the two read as the same Equi at work. Purple in every mood — the
/// shade shifts (violet working, orchid asking, lavender done) and only a
/// failure leaves the family.
struct EquiAgentLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EquiAgentAttributes.self) { context in
            LockScreenCard(context: context)
                .activityBackgroundTint(Night.ground)
                .activitySystemActionForegroundColor(Night.lavender)
                .widgetURL(URL(string: "equitrip://equi"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.trailing) {
                    IslandTrailing(context: context)
                        .padding(.trailing, 6)
                        .padding(.top, 4)
                }
                // The face and the text as one row, in the leading region and
                // dropped below the island: the leading edge is where the eye
                // starts, and the centre region sat inset, under the island.
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 12) {
                        EquiFace(phase: context.state.phase, progress: context.progress, size: 42)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.headline)
                                .font(.system(size: 15.5, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(context.subline)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Night.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    .padding(.leading, 6)
                    .dynamicIsland(verticalPlacement: .belowIfTooWide)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    IslandBottom(context: context)
                        .padding(.horizontal, 6)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                }
            } compactLeading: {
                EquiFace(phase: context.state.phase, progress: context.progress, size: 22, ring: false, halo: false)
            } compactTrailing: {
                CompactTrailing(context: context)
            } minimal: {
                EquiFace(phase: context.state.phase, progress: context.progress, size: 22, ring: context.state.phase == .working, halo: false)
            }
            .keylineTint(context.state.phase.tint)
            .widgetURL(URL(string: "equitrip://equi"))
        }
    }
}

// MARK: - Lock Screen

private struct LockScreenCard: View {
    let context: ActivityViewContext<EquiAgentAttributes>

    private var state: EquiAgentAttributes.ContentState { context.state }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            switch state.phase {
            case .working:
                StepLog(state: state)
                HStack(spacing: 10) {
                    StepBar(total: context.attributes.totalSteps, done: state.completed, phase: state.phase)
                    Text("\(min(state.completed + 1, context.attributes.totalSteps))/\(context.attributes.totalSteps)")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Night.tertiary)
                        .contentTransition(.numericText())
                }
            case .asking:
                Question(context: context, large: true)
            case .done, .stopped, .failed:
                Outcome(state: state, large: true)
                StepBar(total: context.attributes.totalSteps, done: state.completed, phase: state.phase)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background { Aurora(phase: state.phase) }
    }

    private var header: some View {
        HStack(spacing: 12) {
            EquiFace(phase: state.phase, progress: context.progress, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.headline)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(context.subline)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Night.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            switch state.phase {
            case .working:
                // Counting up, so the card visibly lives between steps.
                HStack(spacing: 5) {
                    Circle()
                        .fill(Night.accent)
                        .frame(width: 6, height: 6)
                        .shadow(color: Night.accent, radius: 3)
                    Text(context.attributes.startedAt, style: .timer)
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Night.secondary)
                        .frame(width: 34, alignment: .leading)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(.white.opacity(0.07), in: .capsule)
            case .asking:
                StopButton(runID: context.attributes.runID, labelled: true)
            case .done, .stopped, .failed:
                EmptyView()
            }
        }
    }
}

/// The steps so far: finished ones fading upward, then the one under way,
/// bright — the log a person watching over Equi's shoulder would read.
private struct StepLog: View {
    let state: EquiAgentAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let done = Array(state.trail.suffix(2))
            ForEach(Array(done.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8.5, weight: .heavy))
                        .foregroundStyle(Night.lavender)
                        .frame(width: 18, height: 18)
                        .background(Night.accent.opacity(0.18), in: .circle)
                    Text(step.text)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(index == 0 && done.count > 1 ? 0.36 : 0.56))
                        .lineLimit(1)
                }
            }

            HStack(spacing: 10) {
                Image(systemName: state.step.symbol)
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(
                        LinearGradient(colors: [Night.accent, Night.orchid], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: .circle
                    )
                    .shadow(color: Night.accent.opacity(0.8), radius: 6)
                Text(state.step.text)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .id(state.step.text)
            .transition(.push(from: .bottom))
        }
    }
}

/// Equi's question and the answers, each one a button that reaches the run
/// in the app — see `EquiAgentAnswerIntent`.
private struct Question: View {
    let context: ActivityViewContext<EquiAgentAttributes>
    var large: Bool

    private var options: [EquiAgentAttributes.Option] { context.state.options }

    var body: some View {
        VStack(alignment: .leading, spacing: large ? 12 : 9) {
            Text(context.state.question ?? context.state.step.text)
                .font(.system(size: large ? 17.5 : 15, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Two rows of two when there are four, so each name still fits
            // a thumb.
            let rows = options.count > 3 ? [Array(options.prefix(2)), Array(options.dropFirst(2))] : [options]
            VStack(spacing: 7) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 7) {
                        ForEach(row) { option in
                            Button(intent: EquiAgentAnswerIntent(runID: context.attributes.runID, optionID: option.id)) {
                                Text(option.label)
                                    .font(.system(size: large ? 14.5 : 13.5, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, large ? 11 : 8)
                                    .background {
                                        Capsule().fill(
                                            LinearGradient(
                                                colors: [.white.opacity(0.17), .white.opacity(0.08)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                    }
                                    .overlay { Capsule().strokeBorder(Night.lavender.opacity(0.28), lineWidth: 0.75) }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

/// What the job came to: the thing on the left, its figure large on the
/// right, and a line of detail under both.
private struct Outcome: View {
    let state: EquiAgentAttributes.ContentState
    var large: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                if let outcome = state.outcome {
                    Text(outcome)
                        .font(.system(size: large ? 20 : 16.5, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 6)
                if let value = state.outcomeValue {
                    Text(value)
                        .font(.system(size: large ? 26 : 20, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.white, Night.lavender], startPoint: .top, endPoint: .bottom)
                        )
                        .lineLimit(1)
                        .shadow(color: Night.accent.opacity(0.6), radius: 8)
                }
            }
            if let detail = state.outcomeDetail {
                Text(detail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Night.secondary)
                    .lineLimit(2)
            }
        }
    }
}

private struct StopButton: View {
    let runID: String
    var labelled: Bool

    var body: some View {
        Button(intent: EquiAgentAnswerIntent(runID: runID, optionID: EquiAgentRemote.stopID)) {
            if labelled {
                HStack(spacing: 5) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 8.5, weight: .bold))
                    Text("Stop")
                        .font(.system(size: 12.5, weight: .semibold))
                }
                .foregroundStyle(Night.secondary)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(.white.opacity(0.08), in: .capsule)
            } else {
                // A glyph alone: the island's trailing slot is too narrow for a word.
                Image(systemName: "stop.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Night.secondary)
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.1), in: .circle)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dynamic Island

private struct IslandTrailing: View {
    let context: ActivityViewContext<EquiAgentAttributes>

    var body: some View {
        Group {
            switch context.state.phase {
            case .working:
                Text(context.attributes.startedAt, style: .timer)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Night.secondary)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 46, alignment: .trailing)
            case .asking:
                StopButton(runID: context.attributes.runID, labelled: false)
            case .done:
                if let value = context.state.outcomeValue {
                    Text(value)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.white, Night.lavender], startPoint: .top, endPoint: .bottom))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            case .stopped, .failed:
                EmptyView()
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
}

private struct IslandBottom: View {
    let context: ActivityViewContext<EquiAgentAttributes>

    var body: some View {
        switch context.state.phase {
        case .working:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: context.state.step.symbol)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Night.lavender)
                    Text(context.state.step.text)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .id(context.state.step.text)
                .transition(.push(from: .bottom))

                StepBar(total: context.attributes.totalSteps, done: context.state.completed, phase: .working)
            }
        case .asking:
            Question(context: context, large: false)
        case .done, .stopped, .failed:
            VStack(alignment: .leading, spacing: 10) {
                // The figure is already in the trailing slot; the thing and its
                // detail go here.
                VStack(alignment: .leading, spacing: 2) {
                    if let outcome = context.state.outcome {
                        Text(outcome)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    if let detail = context.state.outcomeDetail {
                        Text(detail)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Night.secondary)
                            .lineLimit(2)
                    }
                }
                StepBar(total: context.attributes.totalSteps, done: context.state.completed, phase: context.state.phase)
            }
        }
    }
}

private struct CompactTrailing: View {
    let context: ActivityViewContext<EquiAgentAttributes>

    var body: some View {
        switch context.state.phase {
        case .working:
            ProgressRing(progress: context.progress, tint: Night.accent, lineWidth: 2.5)
                .frame(width: 18, height: 18)
        case .asking:
            Text("Needs you")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(Night.orchid)
        case .done:
            // What it came to, readable at a glance from the island.
            if let value = context.state.outcomeValue {
                Text(value)
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundStyle(Night.lavender)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: 64)
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Night.lavender)
            }
        case .stopped, .failed:
            Image(systemName: context.state.phase == .failed ? "exclamationmark" : "stop.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(context.state.phase.tint)
        }
    }
}

// MARK: - Pieces

/// Equi's face on its mood's purple, with the run's progress round it — the
/// same badge the app's HUD leads with.
private struct EquiFace: View {
    let phase: EquiAgentAttributes.Phase
    let progress: Double
    let size: CGFloat
    var ring = true
    var halo = true

    var body: some View {
        ZStack {
            if halo {
                Circle()
                    .fill(phase.tint.opacity(0.45))
                    .blur(radius: size * 0.28)
            }

            if ring {
                ProgressRing(progress: phase == .working || phase == .asking ? progress : 1, tint: phase.tint, lineWidth: size * 0.055)
            }

            Circle()
                .fill(LinearGradient(colors: phase.face, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    Circle().strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 0.75
                    )
                }
                .padding(ring ? size * 0.13 : 0)

            glyph
                .font(.system(size: size * (ring ? 0.3 : 0.44), weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var glyph: some View {
        switch phase {
        case .working: Image("Equi")
        case .asking: Image(systemName: "questionmark")
        case .done: Image(systemName: "checkmark")
        case .stopped: Image(systemName: "hand.raised.fill")
        case .failed: Image(systemName: "exclamationmark")
        }
    }
}

private struct ProgressRing: View {
    let progress: Double
    let tint: Color
    var lineWidth: CGFloat = 2.5

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.05, min(1, progress)))
                .stroke(
                    AngularGradient(colors: [tint, Night.orchid, tint], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

/// Progress in steps rather than a smooth bar: a job is a handful of discrete
/// things, and a lit cell per thing done says so. One gradient runs across
/// every cell, so the lit ones read as a single bar warming as it fills.
private struct StepBar: View {
    let total: Int
    let done: Int
    let phase: EquiAgentAttributes.Phase

    var body: some View {
        let count = max(total, 1)
        let lit = phase == .done ? count : min(done, count)

        LinearGradient(colors: phase.bar, startPoint: .leading, endPoint: .trailing)
            .mask {
                HStack(spacing: 3) {
                    ForEach(0..<count, id: \.self) { index in
                        Capsule()
                            .opacity(index < lit ? 1 : (index == lit && phase == .working ? 0.35 : 0))
                    }
                }
            }
            .background {
                HStack(spacing: 3) {
                    ForEach(0..<count, id: \.self) { _ in
                        Capsule().fill(.white.opacity(0.1))
                    }
                }
            }
            .shadow(color: phase.tint.opacity(0.55), radius: 4)
            .frame(height: 5)
    }
}

/// Soft light pooled behind the Lock Screen card — the edge glow's purples.
private struct Aurora: View {
    let phase: EquiAgentAttributes.Phase

    var body: some View {
        ZStack {
            RadialGradient(colors: [phase.tint.opacity(0.5), .clear], center: .topLeading, startRadius: 0, endRadius: 200)
            RadialGradient(colors: [Night.orchid.opacity(phase == .failed ? 0.08 : 0.24), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 230)
            RadialGradient(colors: [Night.indigo.opacity(0.22), .clear], center: .topTrailing, startRadius: 0, endRadius: 170)
        }
    }
}

// MARK: - Palette

/// The Live Activity's own fixed palette, dark whatever the phone's
/// appearance: `Brand`'s dark-mode accent and violet, with the orchid and
/// lavender the edge glow uses.
private enum Night {
    static let ground = rgb(0x120E17)
    static let secondary = Color.white.opacity(0.62)
    static let tertiary = Color.white.opacity(0.42)
    static let accent = rgb(0x9A93FF)
    static let indigo = rgb(0x6A5FE8)
    static let violet = rgb(0xA98BF5)
    static let orchid = rgb(0xD08BF2)
    static let lavender = rgb(0xC9BEFF)
    static let red = rgb(0xFF5A4F)

    static func rgb(_ value: UInt32) -> Color {
        Color(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255)
    }
}

private extension EquiAgentAttributes.Phase {
    var tint: Color {
        switch self {
        case .working: Night.accent
        case .asking: Night.orchid
        case .done: Night.lavender
        case .stopped: Color.white.opacity(0.55)
        case .failed: Night.red
        }
    }

    var face: [Color] {
        switch self {
        case .working: [Night.accent, Night.indigo]
        case .asking: [Night.orchid, Night.rgb(0x8B4FD8)]
        case .done: [Night.violet, Night.rgb(0x6A4FE0)]
        case .stopped: [Night.rgb(0x7D7488), Night.rgb(0x4E4757)]
        case .failed: [Night.red, Night.rgb(0xC5442E)]
        }
    }

    var bar: [Color] {
        switch self {
        case .working, .asking, .done: [Night.indigo, Night.accent, Night.violet, Night.orchid]
        case .stopped: [.white.opacity(0.35), .white.opacity(0.5)]
        case .failed: [Night.red, Night.rgb(0xF08A72)]
        }
    }
}

private extension ActivityViewContext<EquiAgentAttributes> {
    var progress: Double {
        state.phase == .done ? 1 : Double(state.completed) / Double(max(attributes.totalSteps, 1))
    }

    var headline: String {
        switch state.phase {
        case .working: attributes.title
        case .asking: "Equi needs you"
        case .done, .stopped, .failed: state.outcomeTitle ?? "Done"
        }
    }

    var subline: String {
        let context = state.context
        switch state.phase {
        case .working, .done: return context.isEmpty ? "Equi is working in the app" : context
        case .asking, .stopped, .failed: return context.isEmpty ? attributes.title : "\(attributes.title) · \(context)"
        }
    }
}
