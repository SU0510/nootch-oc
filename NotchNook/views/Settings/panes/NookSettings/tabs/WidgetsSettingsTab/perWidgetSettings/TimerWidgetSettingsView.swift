//
//  TimerWidgetSettingsView.swift
//  NotchNook
//
//  Created by Wren on 25/05/26.
//

import SwiftUI
import Settings
import Defaults

struct TimerWidgetSettingsView: View {
    @Default(.timerWidgetSettings) private var settings

    var body: some View {
        Settings.Container(contentWidth: 320) {
            Settings.Section(title: "", bottomDivider: true) {
                Text("Width:")
                SliderPlus(value: $settings.size.width.double, range: 3...8)
            }

            Settings.Section(title: "", bottomDivider: true) {
                Toggle(String(localized: "Show seconds in countdown"), isOn: $settings.showSeconds)
                    .padding(.vertical, 4)
            }

            Settings.Section(title: "", bottomDivider: true) {
                Toggle(String(localized: "Play sound on expiry"), isOn: $settings.playSound)
                    .padding(.vertical, 4)
            }

            Settings.Section(title: "") {
                Text("Default label:")
                TextField("e.g. Tea, Focus…", text: $settings.defaultLabel)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
            }
        }
        .padding(0)
    }
}
