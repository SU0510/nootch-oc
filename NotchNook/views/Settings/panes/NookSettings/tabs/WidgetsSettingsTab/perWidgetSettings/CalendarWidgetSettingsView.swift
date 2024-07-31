//
//  CalendarWidgetSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 08/06/24.
//

import SwiftUI
import Settings
import Defaults

struct CalendarWidgetSettingsView: View {
    @Default(.calendarWidgetSettings) private var calendarWidgetSettings
    @Default(.nookSettings) private var nookSettings
    
//    var availableWidth: NookGrid.Point {
//        let otherEnabledWidgets = nookSettings.enabledWidgets.filter { $0 != .calendar }
//        let usedWidth: NookGrid.Point = otherEnabledWidgets.reduce(.zero) { $0 + $1.prefs.size.width }
//        let freeWidth = nookSettings.size.width - usedWidth
//        return freeWidth
//    }
    
    var body: some View {
        let enabled = nookSettings.enabledWidgets.contains(.calendar)
        Settings.Container(contentWidth: 520.0) {
//            let min: Double = 3
//            let max = !enabled ? 12 : availableWidth.double <= min ? min + 1 : availableWidth.double
            Settings.Section(title: String(localized: "Width:"), bottomDivider: true) {
//                SliderPlus(value: $calendarWidgetSettings.size.width.double, range: min...max)
                SliderPlus(value: $calendarWidgetSettings.size.width.double, range: 3...12)
            }
            Settings.Section(title: String(localized: "Manage other calendar settings:")) {
                Button("Calendar Settings") {
                    openCalendarSettingsAccountsTab()
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
