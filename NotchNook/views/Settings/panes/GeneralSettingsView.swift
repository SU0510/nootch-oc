//
//  GeneralSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/05/24.
//

import SwiftUI
import Settings
import Defaults
import LaunchAtLogin

struct GeneralSettingsView: View {
    @Default(.generalSettings) private var generalSettings
    @Default(.gestureControlSettings) private var gestureControlSettings
    var body: some View {
        let defaultGeneral = GeneralSettings()
//        if !generalSettings.modernSettings {
//            Settings.Container(contentWidth: 542.0) {
//                
//                Settings.Section(title: "") {
//                    LaunchAtLogin.Toggle()
//                    Toggle("Classic looking settings", isOn: $generalSettings.modernSettings)
//                }
//                
//                Settings.Section(title: "Notch") {
//                    Toggle("Transluscent notch background (experimental)", isOn: $generalSettings.transluscent)
//                    Toggle("Always open on hover", isOn: $generalSettings.alwaysOpenNotchOnHover)
//                    Toggle("Disable haptics", isOn: $generalSettings.disableHaptics)
//                }
//                
//                Settings.Section(title: "Handler for non-notched screens") {
//                    CustomLabeled(title: "Width", icon: "arrow.left.and.right") {
//                        SliderPlus(value: $generalSettings.handleSize.width, range: 30...250, step: 16)
//                    }
//                    .resetToDefault($generalSettings.handleSize.width, defaultGeneral.handleSize.width)
//                    
//                    CustomLabeled(title: "Height", icon: "arrow.up.and.down") {
//                        SliderPlus(value: $generalSettings.handleSize.height, range: 1...TopBarView.height)
//                    }
//                    .resetToDefault($generalSettings.handleSize.height, defaultGeneral.handleSize.height)
//                    
//                    Toggle("Transparent handler", isOn: $generalSettings.transparentHandle)
//                    
//                    Text("Will only show up on mouse hover.")
//                        .settingDescription()
//                        .resetToDefault($generalSettings.handleSize.height, defaultGeneral.handleSize.height)
//                }
//                
//                Settings.Section(title: "Trackpad swiping") {
//                    Toggle("Allow gestures when hovering the notch", isOn: $gestureControlSettings.allowGestures)
//                    
//                    if gestureControlSettings.allowGestures {
//                        Toggle(
//                            "Open/close notch with vertical gestures",
//                            isOn: $gestureControlSettings.controlOpenState
//                        )
//                        .disabled(!gestureControlSettings.allowGestures)
//                        
//                        Toggle(
//                            "Control media with horizontal gestures",
//                            isOn: $gestureControlSettings.controlMedia
//                        )
//                        .disabled(!gestureControlSettings.allowGestures)
//                    }
//                }
//                Settings.Section(title: "Others") {
//                    Button("Reset all Settings") { resetDefaults() }
//                    
//                    Text("This will reset everything except your license.")
//                        .settingDescription()
//                }
//            }
//        } else {
            Form {
                Section {
                    LaunchAtLogin.Toggle {
                        Label("Launch on system startup", systemImage: "power")
                    }
//                    Toggle("Modern looking settings", isOn: $generalSettings.modernSettings)
                }
                
                Section("Notch") {
                    Toggle("Transluscent notch background (experimental)", isOn: $generalSettings.transluscent)
                    Toggle("Always open on hover", isOn: $generalSettings.alwaysOpenNotchOnHover)
                    Toggle("Disable haptics", isOn: $generalSettings.disableHaptics)
                }
                
                Section("Handler for non-notched screens") {
                    CustomLabeled(title: "Width", icon: "arrow.left.and.right") {
                        SliderPlus(value: $generalSettings.handleSize.width, range: 30...250, step: 16)
                    }
                    .resetToDefault($generalSettings.handleSize.width, defaultGeneral.handleSize.width)
                    
                    CustomLabeled(title: "Height", icon: "arrow.up.and.down") {
                        SliderPlus(value: $generalSettings.handleSize.height, range: 1...TopBarView.height)
                    }
                    .resetToDefault($generalSettings.handleSize.height, defaultGeneral.handleSize.height)
                    
                    CustomLabeled(title: "Transparent handler", description: "Will only show up on mouse hover.") {
                        Toggle("", isOn: $generalSettings.transparentHandle)
                    }
                    .resetToDefault($generalSettings.handleSize.height, defaultGeneral.handleSize.height)
                }
                
                Section("Trackpad swiping") {
                    Toggle("Allow gestures when hovering the notch", systemImage: "hand.draw", isOn: $gestureControlSettings.allowGestures)
                    
                    Toggle(
                        "Open/close notch with vertical gestures", systemImage: "lightswitch.on",
                        isOn: $gestureControlSettings.controlOpenState
                    )
                    .disabled(!gestureControlSettings.allowGestures)
                    
                    Toggle(
                        "Control media with horizontal gestures", systemImage: "music.note",
                        isOn: $gestureControlSettings.controlMedia
                    )
                    .disabled(!gestureControlSettings.allowGestures)
                }
                
                Section {
                    CustomLabeled(title: "Reset all settings", description: "This will reset everything except your license.") {
                        Button("Reset") { resetDefaults() }
                    }
                }
            }
            .scrollDisabled(true)
            .animation(.default, value: gestureControlSettings.allowGestures)
            .formStyle(.grouped)
            .defaultSettingsProps()
//        }
    }
}
