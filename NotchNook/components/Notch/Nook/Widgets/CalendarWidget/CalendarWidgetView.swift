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
    @State private var calendarManager = CalendarManager.shared
    
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
        @State var events = calendarManager.eventsDatesDict
        
        ScrollWheelViewRepresentable(onDragChanged: onDragChanged, onDragEnded: onDragEnded) {
            VStack(spacing: -1) {
                ScrollableDaysView(displayedDates: displayedDates, selectedDateIndex: $selectedDateIndex, offset: $offset, events: events)
                    .overlay { monthNameOverlayView }
                    .zIndex(1)
                CalendarEventsView(events: events[selectedDate], selectedDate: selectedDate)
                    .id(selectedDate)
            }
        }
        .task {
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            let endDate = Calendar.current.date(byAdding: .day, value: 60, to: Date())!
            try? await calendarManager.fetchEvents(startDate: startDate, endDate: endDate)
        }
    }
    
    var monthNameOverlayView: some View {
        ZStack {
            ScrollableDaysMonthOverlayView(monthName: selectedDate.monthName(.standaloneShort)) {
                withAnimation(.spring) {
                    selectedDateIndex = displayedDates.count / 2
                }
            }
            .id(selectedDate.monthName(.standaloneShort))
            .transition(.scaleAndBlur(anchor: .leading, blur: 0))
        }
        .transition(.scaleAndBlur(anchor: .leading, blur: 0))
        .animation(.snappy, value: selectedDate.monthName(.standaloneShort))
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
