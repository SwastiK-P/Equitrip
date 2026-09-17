//
//  ShakeDetector.swift
//  Equitrip
//

import UIKit

extension Notification.Name {
    /// Posted whenever the system delivers a shake motion event anywhere in
    /// the app. Not gated on the setting here — `RootTabView` is the one
    /// place that knows whether shake-to-add is on, so this fires
    /// unconditionally and lets the listener decide.
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

/// Catches the shake gesture at the window level.
///
/// `motionEnded` only ever reaches whichever responder is first in the
/// chain, and nothing in this app is deliberately made first responder for
/// it — a text field mid-edit would otherwise eat the event and the shake
/// would do nothing while somebody had a keyboard up. Overriding it on
/// `UIWindow` catches it after the responder chain has had its turn, which
/// is the one place guaranteed to see every shake regardless of what's
/// focused.
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}
