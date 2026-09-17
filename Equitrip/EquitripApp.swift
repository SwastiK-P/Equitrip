//
//  EquitripApp.swift
//  Equitrip
//
//  Created by Swastik Patil on 27/08/26.
//

import SwiftUI

@main
struct EquitripApp: App {
    init() {
        // Here and not in a view: the watch can launch the app in the
        // background with no scene, and only a session activated at launch
        // is there to hear it.
        WatchBridge.shared.activate()

        // The Itinerary/Ledger toggle is the app's one segmented control —
        // global appearance is safe rather than incidental. Colours match
        // the same selected/unselected pair every button on the CTA uses,
        // so the native glass control reads as this app's, not iOS's default.
        let selected = UIColor(AppTheme.ctaLabel)
        let unselected = UIColor(AppTheme.inkSecondary)
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(AppTheme.cta)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: selected], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: unselected], for: .normal)
    }

    var body: some Scene {
        WindowGroup {
            // Everything the app lays out adaptively reads `\.pane`, and the
            // reader has to sit outside the screens it describes — including
            // the modal ones, which inherit the environment from whatever
            // presented them rather than measuring themselves.
            PaneReader {
                ContentView()
            }
            // Belt and braces with UIUserInterfaceStyle in the plist, so
            // previews and SwiftUI-hosted sheets match the shipped app.
            .preferredColorScheme(.light)
        }
    }
}
