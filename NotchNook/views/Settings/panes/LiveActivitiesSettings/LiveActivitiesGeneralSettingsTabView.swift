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
            Toggle("Enable live activities", isOn: $liveActivitiesSettings.enable)
            CustomLabeled(
                title: "Inactivity Timeout", icon: "timer",
                description: "Tweak the time _(in seconds)_ that live activities take to go away after they become inactive (like when music pauses)."
            ) {
                HStack(spacing: 8) {
                    Slider(value: $liveActivitiesSettings.inactivityTimeoutInSecs, in: 0...120, step: 10)
                    IntegerTextField(value: $liveActivitiesSettings.inactivityTimeoutInSecs, minVal: 0, maxVal: 600)
                        .frame(width: 40, height: 0)
                }
            }
            CustomLabeled(
                title: "Interactive Activities", icon: "cursorarrow.click",
                description: "Allow some activities to interact with mouse click/hover."
            ) {
                Toggle("", isOn: $liveActivitiesSettings.interactiveActivities)
            }
        }
        .scrollContentBackground(.hidden)
        .formStyle(.grouped)
    }
}
