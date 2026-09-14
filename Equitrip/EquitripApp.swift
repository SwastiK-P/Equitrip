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
