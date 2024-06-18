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
            Settings.Section {
                Text("Width:").frame(minWidth: 150, alignment: .trailing)
            } content: {
                SliderPlus(value: $calendarWidgetSettings.size.width.double, range: 3...5)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
