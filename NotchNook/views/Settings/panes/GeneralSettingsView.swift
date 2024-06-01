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
        Form {
            Section {
                LaunchAtLogin.Toggle {
                    Label("Launch on system startup", systemImage: "power")
                }
            }
            
            Section("Notch") {
                Toggle("Transluscent notch background (experimental)", isOn: $generalSettings.transluscent)
                Toggle("Always open on hover", isOn: $generalSettings.alwaysOpenNotchOnHover)
                Toggle("Disable haptics", isOn: $generalSettings.disableHaptics)
            }
            
            Section("Handler for non-notched screens") {
                Toggle("Transluscent notch background (experimental)", isOn: $generalSettings.transluscent)
                Toggle("Always open on hover", isOn: $generalSettings.alwaysOpenNotchOnHover)
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
                if gestureControlSettings.allowGestures {
                    Toggle(
                        "Open/close notch with vertical gestures", systemImage: "lightswitch.on",
                        isOn: $gestureControlSettings.controlOpenState
                    )
                    Toggle(
                        "Control media with horizontal gestures", systemImage: "music.note",
                        isOn: $gestureControlSettings.controlMedia
                    )
                }
            }
        }
        .scrollDisabled(true)
        .animation(.default, value: gestureControlSettings.allowGestures)
        .formStyle(.grouped)
        .defaultSettingsProps()
    }
}
