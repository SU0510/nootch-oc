//
//  NookSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI
import Settings

struct NookSettingsView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NookGeneralSettingsTabView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)
            WidgetsSettingsTabView()
                .tabItem {
                    Label("Customize widgets", systemImage: "square.stack")
                }
                .tag(1)
        }
        .padding(12)
        .frame(height: 625, alignment: .topLeading)
        .onAppear {
            if let tab = SettingsInnerPath.shared.tabIndex {
                selectedTab = tab
                SettingsInnerPath.shared.tabIndex = nil
            }
        }
    }
}

let NookSettingsViewController: () -> SettingsPane = {
    let paneView = Settings.Pane(
        identifier: .nook,
        title: String(localized: "Nook"),
        toolbarIcon: NSImage(systemSymbolName: "lamp.desk.fill", accessibilityDescription: "Nook settings")!
    ) {
        NookSettingsView()
    }

    return Settings.PaneHostingController(pane: paneView)
}
