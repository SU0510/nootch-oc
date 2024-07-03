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
        let enabled = nookSettings.enabledWidgets.contains(.notes)
        let contentMaxW: Double = 300
        Settings.Container(contentWidth: 520.0) {
            let min: Double = 4
            let max = !enabled ? nookSettings.size.width.double : availableWidth.double <= min ? min + 1 : availableWidth.double
            Settings.Section {
                Text("Width:").frame(minWidth: 200, alignment: .trailing)
            } content: {
                SliderPlus(value: $notesWidgetSettigs.size.width.double, range: min...max)
                Toggle("Show scroll indicator", isOn: $notesWidgetSettigs.showScrollIndicator)
                Toggle("Code mode", isOn: $notesWidgetSettigs.codeMode)
                Text("Transforms notes into a code editor, with syntax highlighting (supports Markdown).")
                    .optionDescription(contentMaxW)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
