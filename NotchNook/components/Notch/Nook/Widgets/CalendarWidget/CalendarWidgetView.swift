//
//  CalendarWidgetView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 04/06/24.
//

import SwiftUI
import Defaults
import SwiftDate

struct CalendarWidgetView: View {
    @Default(.calendarWidgetSettings) private var calendarWidgetSettings
    @State private var selectedDate: Date?
    var body: some View {
        ZStack {
            CalendarView(size: calendarWidgetSettings.size.screenPtsCGSize, events: CalendarManager.shared.events, selectedDate: $selectedDate)
        }
        .task {
            _ = try? await CalendarManager.shared.fetchEvents(
                startDate: Date().dateAtStartOf(.month),
                endDate: Date().dateAtEndOf(.month)
            )
        }
    }
}

