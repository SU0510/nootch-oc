//
//  LiveActivitiesGeneralSettingsTabView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI
import Defaults

struct LiveActivitiesGeneralSettingsTabView: View {
    @Default(.liveActivitiesSettings) private var liveActivitiesSettings
    var body: some View {
        Form {
            Toggle("Enable live activities", isOn: $liveActivitiesSettings.enabled)
            CustomLabeled(
                title: "Inactivity Timeout", icon: "timer",
                description: "Tweak the time _(in seconds)_ that live activities take to go away after they become inactive (like when music pauses)."
            ) {
                HStack(spacing: 8) {
                    SliderPlus(value: $liveActivitiesSettings.inactivityTimeoutInSecs, range: 0...16, rangeManual: 0...600, step: 1)
                }
            }
            CustomLabeled(
                title: "Interactive Activities", icon: "cursorarrow.click",
                description: "Allow some activities to interact with mouse click/hover."
            ) {
                Toggle("", isOn: $liveActivitiesSettings.interactive)
            }
            CustomLabeled(
                title: "Enable Quick Peak", icon: "eyes",
                description: "If enabled, some live activities will show a short info on mouse hover."
            ) {
                Toggle("", isOn: $liveActivitiesSettings.enableQuickPeak)
            }
            
            
        }
        .scrollContentBackground(.hidden)
        .formStyle(.grouped)
    }
}
