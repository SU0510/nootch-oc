//
//  CalendarLiveActivitySettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 13/06/24.
//

import SwiftUI
import Settings
import Defaults

struct CalendarLiveActivitySettingsView: View {
    
    @Default(.calendarLiveActivitySettings) private var calendarLiveActivitySettings
    
    var body: some View {
        Settings.Container(contentWidth: 520.0) {
            Settings.Section(title: String(localized: "Minutes before showing up:")) {
                SliderPlus(value: $calendarLiveActivitySettings.preEventWindow, range: 1...60)
            }
            Settings.Section(title: "", bottomDivider: true) {
                Toggle("Show time lapsed while in events", isOn: $calendarLiveActivitySettings.showEventTimeLapsed)
            }
            Settings.Section(title: String(localized: "Manage other calendar settings:")) {
                Button("Calendar Settings") {
                    openCalendarSettingsAccountsTab()
                }
            }
        }
    }
}
