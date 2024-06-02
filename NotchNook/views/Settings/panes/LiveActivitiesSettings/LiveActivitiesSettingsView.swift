//
//  LiveActivitiesSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

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
        .onAppear {
            if let tab = SettingsInnerPath.shared.tabIndex {
                selectedTab = tab
                SettingsInnerPath.shared.tabIndex = nil
            }
        }
        .defaultSettingsProps(height: 625)
        .task { CurrentWallpaperManager.shared.updateCurrentWallpaper() }
    }
}
