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
        let contentMaxW: Double = 350
        Settings.Container(contentWidth: 520.0, minimumLabelWidth: 150) {
            Settings.Section(title: "", bottomDivider: true) {
                Toggle("Enable nook", isOn: $nookSettings.enabled)
                    .resetToDefault($nookSettings.enabled, defaultValues.enabled)
                Text("If disabled, clicking on the notch won't do anything.")
                    .optionDescription(contentMaxW)
            }
            Settings.Section(title: "") {
                Toggle("Show dividers between widgets", isOn: $nookSettings.showDividers)
                    .resetToDefault($nookSettings.showDividers, defaultValues.showDividers)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
    
}
