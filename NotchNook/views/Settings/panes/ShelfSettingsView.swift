//
//  ShelfSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/05/24.
//

import SwiftUI
import Defaults
import Settings

struct ShelfSettingsView: View {
    @Default(.shelfSettings) private var shelfSettings
    var body: some View {
        let defaultValues = ShelfSettings()
        Settings.Container(contentWidth: 550.0) {
            Settings.Section {
                Text("Width:").frame(minWidth: 150, alignment: .trailing)
            } content: {
                SliderPlus(value: $shelfSettings.size.width.double, range: 8...24)
                    .resetToDefault($shelfSettings.size.width, defaultValues.size.width)
                
                //                CustomLabeled(title: "height", icon: "arrow.up.and.down") {
                //                    SliderPlus(value: $shelfSettings.size.height.double, range: 2...6)
                //                }
                //                .resetToDefault($shelfSettings.size.height, defaultValues.size.height)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}

let ShelfSettingsViewController: () -> SettingsPane = {
    let paneView = Settings.Pane(
        identifier: .shelf,
        title: "Shelf",
        toolbarIcon: NSImage(systemSymbolName: "rectangle.dashed", accessibilityDescription: "Shelf settings")!
    ) {
        ShelfSettingsView()
    }
    
    return Settings.PaneHostingController(pane: paneView)
}
