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
//            MockLiveAcitivitiesView(activities: [.media])
            
            Group {
                CustomLabeled(
                    title: "Minutes before",
                    description: "How many minutes before an event should the live activity show up?"
                ) { SliderPlus(value: $calendarLiveActivitySettings.minutesBeforeEvent, range: 1...60) }
            }
            .listRowInsets(.zero)
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}
