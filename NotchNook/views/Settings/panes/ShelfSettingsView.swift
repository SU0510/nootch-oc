//
//  ShelfSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/05/24.
//

import SwiftUI
import Defaults

struct ShelfSettingsView: View {
    @Default(.shelfSettings) private var shelfSettings
    var body: some View {
        let defaultValues = ShelfSettings()
        Form {
            Section("Size") {
                CustomLabeled(title: "Width", icon: "arrow.left.and.right") {
                    SliderPlus(value: $shelfSettings.size.width.double, range: 8...24)
                }
                .resetToDefault($shelfSettings.size.width, defaultValues.size.width)
                
//                CustomLabeled(title: "height", icon: "arrow.up.and.down") {
//                    SliderPlus(value: $shelfSettings.size.height.double, range: 2...6)
//                }
//                .resetToDefault($shelfSettings.size.height, defaultValues.size.height)
            }
        }
        .formStyle(.grouped)
        .defaultSettingsProps()
    }
}
