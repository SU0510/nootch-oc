//
//  LiveActivitiesGeneralSettingsTabView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI
import Defaults
import Settings

struct LiveActivitiesGeneralSettingsTabView: View {
    @Default(.liveActivitiesSettings) private var liveActivitiesSettings
    
    @Environment(\.volumeAndBrightnessListener) private var volumeAndBrightnessListener
    @State private var disableHUDToggle = false
    
    var body: some View {
        let contentMaxW: Double = 375
        
        Settings.Container(contentWidth: 520.0) {
            Settings.Section(title: "") {
                Toggle("Enable live activities", isOn: $liveActivitiesSettings.enabled)
            }
            
            Settings.Section {
                Text("Inactivity timeout:").frame(minWidth: 150, alignment: .trailing)
            } content: {
                SliderPlus(value: $liveActivitiesSettings.inactivityTimeoutInSecs, range: 0...16, rangeManual: 0...600, step: 1)
                Text("Tweak the time _(in seconds)_ that live activities take to go away after they become inactive (like when music pauses).")
                    .settingDescription()
            }
            
            Settings.Section(title: String(localized: "Interactivity:")) {
                Toggle("Enable interactive activities", isOn: $liveActivitiesSettings.interactive)
                Text("Allow some activities to interact with mouse click.")
                    .settingDescription()
                
                Toggle("Enable Quick Peek", isOn: $liveActivitiesSettings.enableQuickPeek)
                Text("If enabled, some live activities will show a short info on mouse hover.")
                    .settingDescription()
            }
            
            Settings.Section(title: String(localized: "")) {
                HStack {
                    Toggle("Enable volume and brightness HUD replacement", isOn: $liveActivitiesSettings.enableHUDReplacement)
                        .disabled(disableHUDToggle)
                    
                    if disableHUDToggle {
                        ProgressView().controlSize(.small)
                    }
                }
                .onChange(of: liveActivitiesSettings.enableHUDReplacement) { oldValue, newValue in
                    disableHUDToggle = true
                    if newValue {
                        HUDManager.disableSystemHUD()
                        volumeAndBrightnessListener.start()
                    } else {
                        HUDManager.enableSystemHUD()
                        volumeAndBrightnessListener.stop()
                    }
                    doAfter(2) { disableHUDToggle = false }
                }
                Text("This setting requires you to provide NotchNook with accessibility permissions.")
                    .optionDescription(contentMaxW)
                //                Text("If you change this setting, you will need to restart the app to apply your changes.")
                //                    .optionDescription(contentMaxW)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
