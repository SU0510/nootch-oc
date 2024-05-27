//
//  WidgetsSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

struct WidgetsSettingsView: View {
    var body: some View {
        TabView {
            WidgetsGeneralSettingsTabView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            WidgetsCustomizeSettingsTabView()
                .tabItem {
                    Label("Customize widgets", systemImage: "square.stack")
                }
        }
        .defaultSettingsProps()
    }
}
