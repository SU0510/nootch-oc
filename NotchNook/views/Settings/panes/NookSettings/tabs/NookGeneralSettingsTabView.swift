//
//  NookGeneralSettingsTabView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI
import Settings
import Defaults

struct NookGeneralSettingsTabView: View {
    @Default(.nookSettings) private var nookSettings
    var body: some View {
        let defaultValues = NookSettings()
        Settings.Container(contentWidth: 520.0) {
            Settings.Section(title: "") {
                Toggle("Show dividers between widgets", isOn: $nookSettings.showDividers)
                    .resetToDefault($nookSettings.showDividers, defaultValues.showDividers)
            }
            
            Settings.Section(title: "Width:") {
                SliderPlus(value: $nookSettings.size.width.double, range: 8...24)
                    .resetToDefault($nookSettings.size.width, defaultValues.size.width)
                Text("The unit is measured in \"cells\" for the widgets grid. 1 cell means \(NookGrid.point) points/px.")
                    .settingDescription()
                    .frame(maxWidth: 350, alignment: .leading)
                
                //                CustomLabeled(title: "height", icon: "arrow.up.and.down") {
                //                    SliderPlus(value: $nookSettings.size.height.double, range: 2...6)
                //                }
                //                .resetToDefault($nookSettings.size.height, defaultValues.size.height)
            }

            Settings.Section {
                Text("Padding around widgets:").frame(minWidth: 150, alignment: .trailing)
            } content: {
                SliderPlus(value: $nookSettings.widgetsPadding, range: 2...24)
                    .resetToDefault($nookSettings.widgetsPadding, defaultValues.widgetsPadding)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: nookSettings.size.width) { _, newValue in
            var enabledWidgets = nookSettings.enabledWidgets
            var usedSpace = enabledWidgets.reduce(NookGrid.Point.zero) { $0 + $1.prefs.size.width }
            let availableSpace = nookSettings.size.width
            while availableSpace < usedSpace {
                enabledWidgets.removeLast()
                usedSpace = enabledWidgets.reduce(NookGrid.Point.zero) { $0 + $1.prefs.size.width }
            }
            nookSettings.enabledWidgets = enabledWidgets
        }
    }
}
