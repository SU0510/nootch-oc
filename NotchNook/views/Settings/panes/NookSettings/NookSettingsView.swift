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
        .onAppear {
            if let tab = SettingsInnerPath.shared.tabIndex {
                selectedTab = tab
                SettingsInnerPath.shared.tabIndex = nil
            }
        }
        .defaultSettingsProps(height: 625)
    }
}
