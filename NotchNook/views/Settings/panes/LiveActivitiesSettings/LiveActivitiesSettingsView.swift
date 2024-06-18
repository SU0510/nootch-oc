//
//  LiveActivitiesSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI
import Settings

struct LiveActivitiesSettingsView: View {
    @State private var selectedTab: Int = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            LiveActivitiesGeneralSettingsTabView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)
            LiveActivitiesCustomizeSettingsTabView()
                .tabItem {
                    Label("Customize activities", systemImage: "square.stack")
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
        .task { CurrentWallpaperManager.shared.updateCurrentWallpaper() }
    }
}

let LiveActivitiesSettingsViewController: () -> SettingsPane = {
    let paneView = Settings.Pane(
        identifier: .liveActivities,
        title: "Live Activities",
        toolbarIcon: NSImage(systemSymbolName: "clock.badge.fill", accessibilityDescription: "Live activities settings")!
    ) {
        LiveActivitiesSettingsView()
    }

    return Settings.PaneHostingController(pane: paneView)
}
