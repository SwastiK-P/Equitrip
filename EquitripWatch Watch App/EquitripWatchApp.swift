//
//  EquitripWatchApp.swift
//  EquitripWatch Watch App
//

import SwiftUI

@main
struct EquitripWatchApp: App {
    @State private var store: WatchStore = {
        #if DEBUG
        // `xcrun simctl launch <watch> com.swastik.Equitrip.watchkitapp
        // -demoSnapshot` — every screen filled with the sample trip, for
        // reviewing the design without a second account to create data.
        if ProcessInfo.processInfo.arguments.contains("-demoSnapshot") {
            return WatchStore(preview: .placeholder)
        }
        #endif
        return WatchStore()
    }()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(store)
                .tint(Brand.accent)
                .task { store.activate() }
                .modifier(DebugTextSize())
        }
    }
}

/// `-hugeText` alongside the launch, to check every screen at the largest
/// accessibility text size. The watch simulator can't be told to change its
/// text size from the command line, and a layout that only holds at the
/// default size isn't finished.
private struct DebugTextSize: ViewModifier {
    func body(content: Content) -> some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-hugeText") {
            content.dynamicTypeSize(.accessibility2)
        } else {
            content
        }
        #else
        content
        #endif
    }
}
