//
//  EquitripApp.swift
//  Equitrip
//
//  Created by Swastik Patil on 27/08/26.
//

import SwiftUI

@main
struct EquitripApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Belt and braces with UIUserInterfaceStyle in the plist, so
                // previews and SwiftUI-hosted sheets match the shipped app.
                .preferredColorScheme(.light)
        }
    }
}
