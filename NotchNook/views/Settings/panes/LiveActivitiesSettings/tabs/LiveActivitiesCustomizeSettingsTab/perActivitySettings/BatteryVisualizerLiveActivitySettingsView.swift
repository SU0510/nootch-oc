//
//  BatteryLiveActivitySettingsView.swift
//  NotchNook
//
//  Created by Hasan Sultan on 8/18/24.
//

import SwiftUI
import Settings
import Defaults

struct BatteryLiveActivitySettingsView: View {
    @Default(.batteryLiveActivitySettings) private var settings

    var body: some View {
        Settings.Container(contentWidth: 520.0, minimumLabelWidth: 240) {
            Settings.Section(title: String(localized: "Show when plugged in"), bottomDivider: true) {
                Toggle("", isOn: $settings.showWhenPluggedIn)
                    .labelsHidden()
            }
            Settings.Section(title: String(localized: "Show when unplugged"), bottomDivider: true) {
                Toggle("", isOn: $settings.showWhenUnplugged)
                    .labelsHidden()
            }
            Settings.Section(title: String(localized: "Show when fully charged"), bottomDivider: true) {
                Toggle("", isOn: $settings.showWhenFullyCharged)
                    .labelsHidden()
            }
            Settings.Section(title: String(localized: "Show low battery warning"), bottomDivider: true) {
                Toggle("", isOn: $settings.showLowBatteryWarning)
                    .labelsHidden()
            }
            Settings.Section(title: String(localized: "Low battery threshold"), bottomDivider: false) {
                HStack {
                    Text("\(settings.lowBatteryThreshold)%")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .leading)
                    Slider(value: Binding(
                        get: { Double(settings.lowBatteryThreshold) },
                        set: { settings.lowBatteryThreshold = Int($0) }
                    ), in: 5...50, step: 5)
                    .frame(maxWidth: 200)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
