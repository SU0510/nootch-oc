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

    @State private var selectedDateIndex = CalendarManager.numberOfDaysToDisplay / 2
    @State private var displayedDates: [Date] = getRangeOfDays(count: CalendarManager.numberOfDaysToDisplay)
    @State private var offset: Double = 0
    
    var selectedDate: Date {
        let baseDate: Date
        if selectedDateIndex < 0 {
            baseDate = displayedDates[0]
        } else if selectedDateIndex >= displayedDates.count {
            baseDate = displayedDates[displayedDates.count - 1]
        } else {
            baseDate = displayedDates[selectedDateIndex]
        }

        let calendar = Calendar.current
        let date = calendar.startOfDay(for: baseDate)
        return date
    }

    var body: some View {
        let events = CalendarManager.shared.eventsDatesDict
        
        ScrollWheelViewRepresentable(onDragChanged: onDragChanged, onDragEnded: onDragEnded) {
            VStack(spacing: -1) {
                ScrollableDaysView(showingDates: displayedDates, selectedDateIndex: $selectedDateIndex, offset: $offset, events: events)
                    .zIndex(1)
                CalendarEventsView(events: events[selectedDate])
            }
        }
        .environmentObject(CalendarManager.shared)
        .task {
            let startDate = Calendar.current.startOfDay(for: Date())
            let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
            try? await CalendarManager.shared.fetchEvents(startDate: startDate, endDate: endDate)
        }
        .onAppear {
            print("Events for selected date \(selectedDate)): \(events[selectedDate]?.count ?? 0)")
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
