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
        let contentMaxW: Double = 340
        let defaultGeneral = GeneralSettings()
        Settings.Container(contentWidth: 550.0, minimumLabelWidth: 200) {
            
            Settings.Section(title: String(localized: ""), bottomDivider: true) {
                LaunchAtLogin.Toggle {
                    Text("Launch at login")
                }
            }
            
            Settings.Section(title: String(localized: "Notch:")) {
                Toggle("Transluscent notch background (experimental)", isOn: $generalSettings.transluscent)
                Toggle("Always open on hover", isOn: $generalSettings.alwaysOpenNotchOnHover)
                Toggle("Disable haptics", isOn: $generalSettings.disableHaptics)
            }
            Settings.Section(title: "Typing effects:") {
                Toggle("Prevent from closing on mouse leave", isOn: $generalSettings.preventUnhoverCloseWhenTyping)
                Toggle("Lock while typing", isOn: $generalSettings.lockNNWhenTyping)
                    .disabled(!generalSettings.preventUnhoverCloseWhenTyping)
            }
            Settings.Section(title: String(localized: "Content padding:") {
                SliderPlus(value: $generalSettings.contentPadding, range: 0...32)
            }
            Settings.Section(title: String(localized: "Notch width fine tune:"), bottomDivider: true) {
                HStack {
                    Slider(value: $generalSettings.notchWidthFineTune, in: -8...8, step: 1)
                        .frame(maxWidth: 200)
                    let num = generalSettings.notchWidthFineTune
                    Text("\(num > 0 ? "+" : "")\(Int(num))")
                }
                Text("NotchNook tries it's best to guess you notch width, but sometimes it can be a bit off. Here you can fine tune it. It has to be exactly the same size of your notch.")
//                    .settingDescription()
                    .optionDescription(contentMaxW)
            }
            
            Settings.Section(title: String(localized: "Handler (no-notch screens):"), bottomDivider: true) {
                Toggle("Enable", isOn: $generalSettings.enableOnNonNotchScreens)
                
                CustomLabeled(title: String(localized: "Width")) {
                    SliderPlus(value: $generalSettings.handleSize.width, range: 30...250, step: 16)
                }
                .resetToDefault($generalSettings.handleSize.width, defaultGeneral.handleSize.width)
                
                CustomLabeled(title: String(localized: "Height")) {
                    SliderPlus(value: $generalSettings.handleSize.height, range: 1...TopBarView.minHeight)
                }
                .resetToDefault($generalSettings.handleSize.height, defaultGeneral.handleSize.height)
                
                Toggle("Transparent handler", isOn: $generalSettings.transparentHandle)
                
                Text("Will only show up on mouse hover.")
                    .optionDescription(contentMaxW)
                    .resetToDefault($generalSettings.handleSize.height, defaultGeneral.handleSize.height)
            }
            
            Settings.Section(title: String(localized: "Others:")) {
                Button("Reset all settings") { resetDefaults() }
                
                Text("This will reset everything except your license.")
                    .optionDescription(contentMaxW)
                
                Toggle("Demo mode", isOn: $generalSettings.demoMode)
                Text("Prevents NotchNook from hiding when idle. Useful for screen recordings (this has no effect on non-notched screens).")
                    .optionDescription(contentMaxW)
                
                Button("Quit NotchNook") { NSApp.terminate(nil) }
                Text("You can also right click it.")
                    .optionDescription(contentMaxW)
            }
        }
        .frame(width: 610)
    }
}

let GeneralSettingsViewController: () -> SettingsPane = {
    let paneView = Settings.Pane(
        identifier: .general,
        title: String(localized: "General"),
        toolbarIcon: NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: "General settings")!
    ) {
        GeneralSettingsView()
    }
    
    return Settings.PaneHostingController(pane: paneView)
}
