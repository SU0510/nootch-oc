//
//  DropAreaSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/05/24.
//

import SwiftUI
import Defaults
import Settings

struct DropAreaSettingsView: View {
    var body: some View {
        TabView {
            DropAreaGeneralSettingsTabView()
                .tabItem { Text("General") }
            PipelinesSettingsTabView()
                .tabItem { Text("Customize pipelines") }
        }
        .padding(12)
        .frame(height: 625, alignment: .topLeading)
    }
}

let DropAreaSettingsViewController: () -> SettingsPane = {
    let paneView = Settings.Pane(
        identifier: .dropArea,
        title: String(localized: "Drop Area"),
        toolbarIcon: NSImage(systemSymbolName: "cursorarrow.and.square.on.square.dashed", accessibilityDescription: "Drop area settings")!
    ) {
        DropAreaSettingsView()
    }

    return Settings.PaneHostingController(pane: paneView)
}
