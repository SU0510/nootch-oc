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
    
    @Default(.calendarWidgetSettings) private var settings
    
    var body: some View {
        Settings.Container(contentWidth: 520.0, minimumLabelWidth: 200) {
            Settings.Section(title: String(localized: "Width:")) {
                SliderPlus(value: $settings.size.width.double, range: 3...12)
            }
            
            Settings.Section(title: "") {
                Toggle(String(localized: "Show today's past events"), isOn: $settings.shouldShowTodayPastEvents)
                    .padding(.top)
            }
            
            Settings.Section(title: String(localized: "Number of days behind:")) {
                SliderPlus(value: $settings.numberOfDaysBehindToDisplay, range: 0...21)
                    .padding(.top)
            }
            
            Settings.Section(title: String(localized: "Number of days ahead:"), bottomDivider: true) {
                SliderPlus(value: $settings.numberOfDaysAheadToDisplay, range: 0...21)
            }
            
            Settings.Section(title: String(localized: "Other calendar settings:")) {
                Button("Calendar Settings") {
                    openCalendarSettingsAccountsTab()
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
