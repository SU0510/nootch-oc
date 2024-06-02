//
//  DropAreaSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/05/24.
//

import SwiftUI
import Defaults

struct DropAreaSettingsView: View {
    var body: some View {
        TabView {
            DropAreaGeneralSettingsTabView()
                .tabItem { Text("General") }
            PipelinesSettingsTabView()
                .tabItem { Text("Customize pipelines") }
        }
        .padding(12)
        .defaultSettingsProps(height: 200)
    }
}
