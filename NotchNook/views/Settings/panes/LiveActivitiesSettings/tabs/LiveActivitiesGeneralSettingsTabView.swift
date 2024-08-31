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
    @Environment(\.generalSettings) private var generalSettings
    @State private var disableHUDToggle = false
    
    var body: some View {
        let contentMaxW: Double = 375
        
        Settings.Container(contentWidth: 520.0) {
            Settings.Section(title: "", bottomDivider: true) {
                Toggle("Enable live activities", isOn: $liveActivitiesSettings.enabled)
                    .padding(.bottom, 10)
            }
            
            Settings.Section {
                Text("Inactivity timeout:")
                    .frame(minWidth: 150, alignment: .trailing)
            } content: {
                SliderPlus(value: $liveActivitiesSettings.inactivityTimeoutInSecs, range: 0...16, rangeManual: 0...600, step: 1)
                    .disabled(!liveActivitiesSettings.enabled)
                    .padding(.top, 10)

                Text("Tweak the time _(in seconds)_ that live activities take to go away after they become inactive (like when music pauses).")
                    .settingDescription()
            }
            
            Settings.Section(title: String(localized: "Interactivity:"), bottomDivider: true) {
                Toggle("Enable interactive activities", isOn: $liveActivitiesSettings.interactive)
                    .disabled(!liveActivitiesSettings.enabled)

                Text("Allow some activities to interact with mouse click.")
                    .settingDescription()
                    .foregroundColor(liveActivitiesSettings.enabled ? .nonShockingWhite : .gray)
                
                Toggle("Enable Quick Peek", isOn: $liveActivitiesSettings.enableQuickPeek)
                    .disabled(!liveActivitiesSettings.enabled)

                Text("If enabled, some live activities will show a short info on mouse hover.")
                    .settingDescription()
                                
                Toggle("Unhide Automatically", isOn: $liveActivitiesSettings.unhideAutomatically)
                    .disabled(!liveActivitiesSettings.enabled)

                Text("If enabled, live activities that have been dismissed (by swiping up) will automatically return.")
                    .settingDescription()
                
                Toggle("Show song change", isOn: $liveActivitiesSettings.quickPeekEvent)
                    .disabled(!liveActivitiesSettings.enabled)

                Text("Show when a song changes while playing media via quick peek.")
                    .settingDescription()
            }
            
            Settings.Section(title: String(localized: "HUD replacement:"), bottomDivider: true) {
                HStack(spacing: 8) {
                    Toggle("Enable", isOn: $liveActivitiesSettings.enableHUDReplacement)
                        .disabled(disableHUDToggle)
                        .disabled(!liveActivitiesSettings.enabled)
                    
                    ProgressView().controlSize(.mini)
                        .opacity(disableHUDToggle ? 1 : 0)
                }
                .onChange(of: liveActivitiesSettings.enableHUDReplacement) { oldValue, newValue in
                    disableHUDToggle = true
                    if !newValue {
                        VolumeAndBrightnessListener.shared.stop()
                    }
                    doAfter(2) { disableHUDToggle = false }
                }
                Text("This setting requires you to provide NotchNook with accessibility permissions.")
                    .optionDescription(contentMaxW)
                
                Toggle("Disable colors on audio HUD replacement", isOn: $liveActivitiesSettings.disableColorsOnAudioHUDReplacement)
                    .fixedSize()
                    .disabled(!liveActivitiesSettings.enableHUDReplacement)
                    .disabled(!liveActivitiesSettings.enabled)
            }
            
            Settings.Section(title: String(localized: "Handler (no-notch screens):")) {
                CustomLabeled(title: String(localized: "Height")) {
                    SliderPlus(
                        value: $liveActivitiesSettings.height,
                        range: generalSettings.handleSize.height...TopBarView.maxHeight,
                        useTickMarks: true
                    )
                        .disabled(!liveActivitiesSettings.enabled)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
