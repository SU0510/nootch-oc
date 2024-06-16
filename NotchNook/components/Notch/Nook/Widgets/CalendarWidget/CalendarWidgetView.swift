//
//  CalendarWidgetView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 08/06/24.
//

import SwiftUI
import Defaults
import EventKit
import SwiftDate

struct CalendarWidgetView: View {
    static let showingDatesCount = 90
    @Default(.calendarWidgetSettings) private var calendarWidgetSettings
    @State private var selectedDateIndex = Self.showingDatesCount / 2
    @State private var showingDates: [Date] = getRangeOfDays(count: Self.showingDatesCount)
    @State private var offset: Double = 0
    
    var selectedDate: Date {
        if selectedDateIndex < 0 { return showingDates[0] }
        if selectedDateIndex >= showingDates.count { return showingDates[showingDates.count - 1] }
        return showingDates[selectedDateIndex]
    }
    
    var body: some View {
        let events = CalendarManager.shared.eventsDatesDict
        ScrollWheelViewRepresentable(onDragChanged: onDragChanged, onDragEnded: onDragEnded) {
            VStack(spacing: -1) {
                ScrollableDaysView(showingDates: showingDates, selectedDateIndex: $selectedDateIndex, offset: $offset, events: events)
                    .zIndex(1)
                CalendarEventsView(events: events[selectedDate])
            }
        }
        .task {
            _ = try? await CalendarManager.shared.fetchEventsForDaysOffset(CalendarWidgetView.showingDatesCount)
        }
    }
    
    // MARK: - Functions
    
    func onDragChanged(_ translation: CGSize, _ scrollingPoint: CGPoint, _ velocity: CGSize, cancelGesture: () -> ()) {
        offset += scrollingPoint.x * 0.25
    }
    
    func onDragEnded(_ translation: CGSize, _ scrollingPoint: CGPoint, _ velocity: CGSize) {
        withAnimation(.spring) {
            selectedDateIndex += abs(velocity.width) > 10 ? velocity.width > 0 ? 1 : -1 : 0
            offset = 0
        }
    }
}
