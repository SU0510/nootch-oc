//
//  GeneralSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/05/24.
//

import SwiftUI
import Settings
import Defaults

struct GeneralSettingsView: View {
    @Default(.inactiveLiveActivitiesTimeout) private var inactiveLiveActivitiesTimeout
    var body: some View {
//        Settings.Container(contentWidth: 450.0) {
            List {
                Section {
                    LabeledContent("Inactive live activities timeout") {
                        Slider(value: $inactiveLiveActivitiesTimeout, in: 0...180)
//                        Ran
//                        TextField("", text: <#T##Binding<String>#>)
                    }
                }
            }
            .listStyle(.inset)
            .defaultSettingsPaneSize()
//            Settings.Section(title: "Section Title") {
//                Text("Oie!")
//            }
//            Settings.Section(label: {
//                // Custom label aligned on the right side.
//            }) {
//                // Some view.
//            }
//        }
        .transition(.identity)
    }
}
