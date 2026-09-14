//
//  ControlRoutes.swift
//  Equitrip
//

import Foundation

/// Hears a Control Centre / Lock Screen button press while the app is already
/// running.
///
/// The route itself travels through the shared app group, and the app reads it
/// on launch and on every return to the foreground. That covers everything
/// except the case the control is most used in: Control Centre is drawn *over*
/// the running app without ever backgrounding it, so a press there brings
/// forward an app that never left and no `scenePhase` change ever arrives to
/// read the route on.
///
/// A Darwin notification crosses the process boundary with no entitlement and
/// no payload, which is exactly the shape of the problem — "look again" is the
/// whole message. Its callback is a bare C function pointer and can capture
/// nothing, so it re-posts onto `NotificationCenter`, which SwiftUI can watch.
enum ControlRoutes {

    /// What views observe. Carries nothing: the listener's job is only to say
    /// that something was posted, and `SharedStore.takePendingRoute()` says
    /// what it was.
    static let posted = Notification.Name(SharedStore.routePostedNotification)

    private static var started = false

    /// Idempotent, and never torn down — one process-wide observer costs
    /// nothing and there is no moment in the app's life where it would be
    /// right to stop listening for this.
    static func startListening() {
        guard !started else { return }
        started = true

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            { _, _, _, _, _ in
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: ControlRoutes.posted, object: nil)
                }
            },
            SharedStore.routePostedNotification as CFString,
            nil,
            .deliverImmediately
        )
    }
}
