//
//  TraySettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/05/24.
//

import SwiftUI
import Defaults
import Settings

struct TraySettingsView: View {
    @Default(.traySettings) private var traySettings
    var body: some View {
        let defaultValues = TraySettings()
        Settings.Container(contentWidth: 550.0) {
            Settings.Section {
                Text("Width:").frame(minWidth: 150, alignment: .trailing)
            } content: {
                SliderPlus(value: $traySettings.size.width.double, range: 8...24)
                    .resetToDefault($traySettings.size.width, defaultValues.size.width)
                
                //                CustomLabeled(title: "height", icon: "arrow.up.and.down") {
                //                    SliderPlus(value: $traySettings.size.height.double, range: 2...6)
                //                }
                //                .resetToDefault($traySettings.size.height, defaultValues.size.height)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}

let TraySettingsViewController: () -> SettingsPane = {
    let paneView = Settings.Pane(
        identifier: .tray,
        title: String(localized: "Tray"),
        toolbarIcon: NSImage(systemSymbolName: "rectangle.dashed", accessibilityDescription: "Tray settings")!
    ) {
        TraySettingsView()
    }
    
    return Settings.PaneHostingController(pane: paneView)
}
