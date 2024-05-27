//
//  LiveActivitiesSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

struct LiveActivitiesSettingsView: View {
    var body: some View {
        TabView {
            LiveActivitiesGeneralSettingsTabView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            LiveActivitiesCustomizeSettingsTabView()
                .tabItem {
                    Label("Customize activities", systemImage: "square.stack")
                }
        }
        .padding(8)
        .defaultSettingsProps()
        .task { CurrentWallpaperManager.shared.updateCurrentWallpaper() }
    }
}
