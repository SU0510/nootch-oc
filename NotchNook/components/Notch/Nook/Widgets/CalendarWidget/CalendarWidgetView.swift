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
    static let showingDatesCount = 45 // Please use an odd number here (for centering matters)
    @Default(.calendarWidgetSettings) private var calendarWidgetSettings
    @State private var selectedDateIndex = Self.showingDatesCount / 2
    @State private var showingDates: [Date] = getRangeOfDays(count: Self.showingDatesCount)
    @State private var offset: Double = 0
    @State private var events = [Date:[EKEvent]]()
    //    @State private var dragging = false
    
    var selectedDate: Date { showingDates[selectedDateIndex] }
    
    var body: some View {
        ScrollWheelViewRepresentable(onDragChanged: onDragChanged, onDragEnded: onDragEnded) {
            //            VStack(spacing: -12) {
            VStack(spacing: -1) {
                ScrollableDaysView(showingDates: showingDates, selectedDateIndex: $selectedDateIndex, offset: $offset, events: events)
                    .zIndex(1)
                CalendarEventsView(events: events[selectedDate])
            }
        }
        .onChange(of: CalendarManager.shared.events, initial: true) { _, _ in
            events = groupAndSortEventsByDate(events: CalendarManager.shared.events)
            //            for event in events {
            //                print(event.key, event.value)
            //            }
            //            print(events.keys,)
        }
        .task {
            _ = try? await CalendarManager.shared.fetchEvents(
                startDate: Date().dateAtStartOf(.month),
                endDate: Date().dateAtEndOf(.month)
            )
        }
    }
    
    // MARK: - Functions
    
    func onDragChanged(_ translation: CGSize, _ scrollingPoint: CGPoint, _ velocity: CGSize, cancelGesture: () -> ()) {
        //        dragging = true
        //        print(scrollingPoint.x)
        offset += scrollingPoint.x * 0.25
    }
    
    func onDragEnded(_ translation: CGSize, _ scrollingPoint: CGPoint, _ velocity: CGSize) {
        //        dragging = false
        offset = 0
    }
}
