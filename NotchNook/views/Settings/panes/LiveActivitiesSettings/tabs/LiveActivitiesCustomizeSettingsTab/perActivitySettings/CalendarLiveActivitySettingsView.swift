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
            Settings.Section {
                Text("Minutes before showing up:").frame(minWidth: 200, alignment: .trailing)
            } content: {
                SliderPlus(value: $calendarLiveActivitySettings.minutesBeforeEvent, range: 1...60)
            }
            Settings.Section(title: "Other options:") {
                Toggle("Show while in events", isOn: $calendarLiveActivitySettings.showWhileInEvent)
                
                if calendarLiveActivitySettings.showWhileInEvent {
                    Toggle("Show time lapsed while in events", isOn: $calendarLiveActivitySettings.showEventTimeLapsed)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .animation(.default, value: calendarLiveActivitySettings.showWhileInEvent)
    }
}
