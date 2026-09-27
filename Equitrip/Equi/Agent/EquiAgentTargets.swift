//
//  EquiAgentTargets.swift
//  Equitrip
//

import SwiftUI
import UIKit

/// Everything Equi can press, type into or scroll, keyed by a stable id: where
/// it is on screen right now, and what pressing it does.
///
/// Apps can't post touches to themselves, so a control opts in instead — the
/// screen hands over the same closure its own button runs, and a probe view
/// behind the control answers "where are you?" in window coordinates at the
/// moment of asking. Asked late rather than recorded on layout: a sheet slides
/// in by transform, which SwiftUI's geometry callbacks never see, and a frame
/// captured as it appeared would aim the cursor off the bottom of the screen.
///
/// The press is the screen's own action, so a run goes through exactly the
/// code a finger would — the sheet's own `commit`, its own toast, its own
/// dismissal — rather than a parallel path that could drift from it.
@MainActor
final class EquiAgentTargets {
    static let shared = EquiAgentTargets()

    /// What a control hands over. A control can be any of the three at once.
    struct Handlers {
        var perform: (() -> Void)?
        var setText: ((String) -> Void)?
        /// For a scroll container: brings the view with this id into sight.
        var reveal: ((String) -> Void)?
        /// For a date or time picker, which can't be typed into.
        var setDate: ((Date) -> Void)?
    }

    private struct Entry {
        weak var probe: EquiAgentProbeView?
        var locate: (() -> CGRect?)?
        var handlers: Handlers
    }

    /// Newest last: when the same id is on screen twice — a tab kept alive
    /// under a sheet — the most recently shown one wins, if it's visible.
    private var entries: [String: [Entry]] = [:]

    private init() {}

    // MARK: Registration

    func register(_ id: String, probe: EquiAgentProbeView, handlers: Handlers) {
        var list = (entries[id] ?? []).filter { $0.probe != nil && $0.probe !== probe }
        list.append(Entry(probe: probe, handlers: handlers))
        entries[id] = list
    }

    func update(_ id: String, probe: EquiAgentProbeView, handlers: Handlers) {
        guard let index = entries[id]?.firstIndex(where: { $0.probe === probe }) else {
            register(id, probe: probe, handlers: handlers)
            return
        }
        entries[id]?[index].handlers = handlers
    }

    func unregister(_ id: String, probe: EquiAgentProbeView) {
        entries[id]?.removeAll { $0.probe == nil || $0.probe === probe }
    }

    /// A control with no SwiftUI view to hang a probe on — the tab bar's items.
    func register(_ id: String, locate: @escaping () -> CGRect?, perform: @escaping () -> Void) {
        entries[id] = [Entry(probe: nil, locate: locate, handlers: Handlers(perform: perform))]
    }

    // MARK: Lookup

    /// The control's frame in screen points and what it does, if it's on
    /// screen now.
    func resolve(_ id: String) -> (frame: CGRect, handlers: Handlers)? {
        for entry in (entries[id] ?? []).reversed() {
            if let locate = entry.locate {
                if let frame = locate() { return (frame, entry.handlers) }
                continue
            }
            guard let probe = entry.probe, let frame = probe.visibleFrame else { continue }
            return (frame, entry.handlers)
        }
        return nil
    }

    /// The handlers alone, visible or not — for tidying up after a run that
    /// finished with the screen off.
    func handlers(_ id: String) -> Handlers? {
        (entries[id] ?? []).last { $0.probe != nil || $0.locate != nil }?.handlers
    }

    // MARK: Tab bar

    /// Where the tab bar draws the item with this title, in screen points.
    ///
    /// The tab bar is UIKit's and has no SwiftUI view to probe, so this finds
    /// it in the window and asks its item views, by their accessibility label,
    /// where they are. If the bar's internals ever stop answering that, the
    /// item's slot is worked out from the bar's own frame instead — close
    /// enough to aim a cursor at, which is all this is for.
    static func tabBarItemFrame(title: String, index: Int, count: Int) -> CGRect? {
        guard let window = mainWindow, let bar = findTabBar(in: window), !bar.isHidden, bar.alpha > 0.01 else { return nil }

        var matches: [UIView] = []
        collect(in: bar, label: title, into: &matches)
        if let item = matches
            .filter({ $0.bounds.width > 20 && $0.bounds.height > 20 && $0.window != nil })
            .min(by: { $0.bounds.width * $0.bounds.height < $1.bounds.width * $1.bounds.height }) {
            return item.convert(item.bounds, to: nil)
        }

        let frame = bar.convert(bar.bounds, to: nil)
        let slot = frame.width / CGFloat(max(count, 1))
        return CGRect(x: frame.minX + slot * CGFloat(index), y: frame.minY, width: slot, height: min(frame.height, 64))
    }

    /// The app's own window — never the overlays that sit above it.
    static var mainWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.windowLevel == .normal && !$0.isHidden && $0.rootViewController != nil }
    }

    private static func findTabBar(in view: UIView) -> UITabBar? {
        if let bar = view as? UITabBar { return bar }
        for sub in view.subviews {
            if let bar = findTabBar(in: sub) { return bar }
        }
        return nil
    }

    private static func collect(in view: UIView, label: String, into matches: inout [UIView]) {
        if view.accessibilityLabel?.caseInsensitiveCompare(label) == .orderedSame { matches.append(view) }
        for sub in view.subviews where !sub.isHidden {
            collect(in: sub, label: label, into: &matches)
        }
    }
}

// MARK: - Probe

/// An invisible view laid behind a control, standing in for it in UIKit so
/// its on-screen frame can be asked for at any moment.
final class EquiAgentProbeView: UIView {
    var targetID: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Its frame in screen points, or nil when it can't be seen: not in a
    /// window (a tab that isn't selected), or under something hidden.
    var visibleFrame: CGRect? {
        guard let window, window.windowLevel == .normal, bounds.width > 0 || bounds.height > 0 else { return nil }
        var view: UIView? = self
        while let current = view {
            if current.isHidden || current.alpha < 0.01 { return nil }
            view = current.superview
        }
        let frame = convert(bounds, to: nil)
        guard frame.intersects(window.bounds) else { return nil }
        return frame
    }
}

private struct EquiAgentProbe: UIViewRepresentable {
    let id: String
    let handlers: EquiAgentTargets.Handlers

    func makeUIView(context: Context) -> EquiAgentProbeView {
        let view = EquiAgentProbeView()
        view.targetID = id
        EquiAgentTargets.shared.register(id, probe: view, handlers: handlers)
        return view
    }

    func updateUIView(_ view: EquiAgentProbeView, context: Context) {
        // The closures capture the view's state as of this pass; the old ones
        // would press a button with yesterday's values behind it.
        if view.targetID != id, let old = view.targetID {
            EquiAgentTargets.shared.unregister(old, probe: view)
            view.targetID = id
        }
        EquiAgentTargets.shared.update(id, probe: view, handlers: handlers)
    }

    static func dismantleUIView(_ view: EquiAgentProbeView, coordinator: ()) {
        if let id = view.targetID { EquiAgentTargets.shared.unregister(id, probe: view) }
    }
}

extension View {
    /// Lets Equi press this control. `perform` is what a tap on it does — pass
    /// the button's own action, not a second copy of it. A nil id opts out,
    /// for rows where only some instances are pressable.
    func agentTarget(_ id: String?, perform: @escaping () -> Void) -> some View {
        background {
            if let id { EquiAgentProbe(id: id, handlers: .init(perform: perform)) }
        }
    }

    /// Lets Equi type into this field, a character at a time.
    func agentField(_ id: String, text: Binding<String>) -> some View {
        background {
            EquiAgentProbe(id: id, handlers: .init(setText: { text.wrappedValue = $0 }))
        }
    }

    /// Lets Equi set this picker. `set` is what the picker's own binding does.
    func agentDate(_ id: String, set: @escaping (Date) -> Void) -> some View {
        background {
            EquiAgentProbe(id: id, handlers: .init(setDate: set))
        }
    }

    /// Lets Equi scroll this container to a view carrying `.id(_:)`.
    func agentScroller(_ id: String, reveal: @escaping (String) -> Void) -> some View {
        background {
            EquiAgentProbe(id: id, handlers: .init(reveal: reveal))
        }
    }
}
