//
//  NotesWidgetSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/06/24.
//

import SwiftUI
import Settings
import Defaults

struct NotesWidgetSettingsView: View {
    @Default(.notesWidgetSettigs) private var notesWidgetSettigs
    @Default(.nookSettings) private var nookSettings
    
    var availableWidth: NookGrid.Point {
        let otherEnabledWidgets = nookSettings.enabledWidgets.filter { $0 != .notes }
        let usedWidth: NookGrid.Point = otherEnabledWidgets.reduce(.zero) { $0 + $1.prefs.size.width }
        let freeWidth = nookSettings.size.width - usedWidth
        return freeWidth
    }
    
    var body: some View {
        let enabled = nookSettings.enabledWidgets.contains(.calendar)
        Settings.Container(contentWidth: 520.0) {
            let min: Double = 3
            let max = !enabled ? 12 : availableWidth.double <= min ? min + 1 : availableWidth.double
            Settings.Section(title: "Width", bottomDivider: true) {
                SliderPlus(value: $notesWidgetSettigs.size.width.double, range: min...max)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
