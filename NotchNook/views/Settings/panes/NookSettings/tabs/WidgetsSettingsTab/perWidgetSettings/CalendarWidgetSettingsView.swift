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
    var body: some View {
        Settings.Container(contentWidth: 520.0) {
            Settings.Section(title: "Width", bottomDivider: true) {
                SliderPlus(value: $calendarWidgetSettings.size.width.double, range: 3...7)
            }
            Settings.Section(title: "Manage other calendar settings:") {
                Button("Calendar Settings") {
                    openCalendarSettingsAccountsTab()
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
