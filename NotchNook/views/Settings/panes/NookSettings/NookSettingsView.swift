//
//  NookSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

struct NookSettingsView: View {
    var body: some View {
        TabView {
            NookGeneralSettingsTabView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            WidgetsSettingsTabView()
                .tabItem {
                    Label("Customize widgets", systemImage: "square.stack")
                }
        }
        .padding(12)
        .defaultSettingsProps()
    }
}
