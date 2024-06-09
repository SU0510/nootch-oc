//
//  CalendarWidgetSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 08/06/24.
//

import SwiftUI
import Defaults

struct CalendarWidgetSettingsView: View {
    @Default(.calendarWidgetSettings) private var calendarWidgetSettings
    var body: some View {
        Form {
            CustomLabeled(title: "Width") {
                SliderPlus(value: $calendarWidgetSettings.size.width.double, range: 3...5)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}
