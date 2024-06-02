//
//  DropAreaGeneralSettingsTabView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI
import Defaults

struct DropAreaGeneralSettingsTabView: View {
    @Default(.dropAreaSettings) private var dropAreaSettings
    
    var body: some View {
        let defaultValues = DropAreaSettings()
        Form {
            Section("Size") {
                CustomLabeled(title: "Width", icon: "arrow.left.and.right") {
                    SliderPlus(value: $dropAreaSettings.size.width.double, range: 8...24)
                }
                .resetToDefault($dropAreaSettings.size.width, defaultValues.size.width)
                
                //                CustomLabeled(title: "height", icon: "arrow.up.and.down") {
                //                    SliderPlus(value: $dropAreaSettings.size.height.double, range: 2...6)
                //                }
                //                .resetToDefault($dropAreaSettings.size.height, defaultValues.size.height)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}
