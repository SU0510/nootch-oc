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
        Form {
            Section {
                LaunchAtLogin.Toggle {
                    Label("Launch on system startup", systemImage: "power")
                }
            }
            
            Section("Notch") {
                Toggle("Transluscent notch background (experimental)", isOn: $generalSettings.transluscent)
                Toggle("Always open on hover", isOn: $generalSettings.alwaysOpenNotchOnHover)
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
