//
//  CalendarLiveActivitySettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 13/06/24.
//

import SwiftUI
import Defaults

struct CalendarLiveActivitySettingsView: View {
    @Default(.calendarLiveActivitySettings) private var calendarLiveActivitySettings
    var body: some View {
        Form {
            CustomLabeled(
                title: "Minutes before",
                description: "How many minutes before an event should the live activity show up?"
            ) { SliderPlus(value: $calendarLiveActivitySettings.minutesBeforeEvent, range: 1...60) }
            
            Toggle("Show while in events", isOn: $calendarLiveActivitySettings.showWhileInEvent)
            
            if calendarLiveActivitySettings.showWhileInEvent {
                Toggle("Show time lapsed while in events", isOn: $calendarLiveActivitySettings.showEventTimeLapsed)
            }
        }
        .animation(.default, value: calendarLiveActivitySettings.showWhileInEvent)
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}
