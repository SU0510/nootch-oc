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
            Settings.Section(title: "Minutes before showing up:") {
                SliderPlus(value: $calendarLiveActivitySettings.minutesBeforeEvent, range: 1...60)
            }
            Settings.Section(title: "Other options:", bottomDivider: true) {
                Toggle("Show while in events", isOn: $calendarLiveActivitySettings.showWhileInEvent)
                
                if calendarLiveActivitySettings.showWhileInEvent {
                    Toggle("Show time lapsed while in events", isOn: $calendarLiveActivitySettings.showEventTimeLapsed)
                }
            }
            Settings.Section(title: "Manage other calendar settings:") {
                Button("Calendar Settings") {
                    openCalendarSettingsAccountsTab()
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .animation(.default, value: calendarLiveActivitySettings.showWhileInEvent)
    }
}
