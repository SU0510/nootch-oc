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
    
    @State private var selectedDateIndex: Int = 0
    @State private var offset: Double = 0
    @State private var calendarManager = CalendarManager.shared
    @State private var displayedDates: [Date] = []
    @State private var dragDirection: CGFloat = 0
    
    @Environment(\.calendarWidgetSettings) private var settings
    @Environment(\.openURL) private var openURL
    
    var daysBehindCount: Int {
        settings.numberOfDaysBehindToDisplay
    }
    
    var selectedDate: Date {
        let safeIndex = max(0, min(selectedDateIndex, displayedDates.count - 1))
        let baseDate = displayedDates.isEmpty ? Date() : displayedDates[safeIndex]
        
        let date = Calendar.current.startOfDay(for: baseDate)
        
        return date
    }
    
    var body: some View {
        let events = calendarManager.eventsDatesDict

        ScrollWheelViewRepresentable(onDragChanged: onDragChanged, onDragEnded: onDragEnded) {
            VStack(spacing: -1) {
                // MARK: Days carrousel
                ScrollableDaysView(displayedDates: displayedDates, selectedDateIndex: $selectedDateIndex, offset: $offset, events: events)
                    .overlay {
                        // MARK: Month view
                        ZStack {
                            ScrollableDaysMonthOverlayView(monthName: selectedDate.monthName(.standaloneShort)) {
                                if selectedDateIndex != daysBehindCount {
                                    withAnimation(.spring) {
                                        selectedDateIndex = daysBehindCount
                                    }
                                } else {
                                    guard let url = URL(string: "ical://") else { return }
                                    openURL(url)
                                }
                            }
                            .id(selectedDate.monthName(.standaloneShort))
                            .transition(.scaleAndBlur(anchor: .leading, blur: 0))
                        }
                        .transition(.scaleAndBlur(anchor: .leading, blur: 0))
                        .animation(.snappy, value: selectedDate.monthName(.standaloneShort))
                    }
                    .zIndex(1)
                
                // MARK: Events vertical scroll
                CalendarEventsView(events: events[selectedDate], selectedDate: selectedDate)
                    .id(selectedDate)
            }
        }
        .frame(settings.size.screenPtsCGSize, .leading)
        .onAppear {
            displayedDates = getRangeOfDays(beforeCount: daysBehindCount, afterCount: settings.numberOfDaysAheadToDisplay)
            selectedDateIndex = daysBehindCount
        }
    }

    // MARK: - Functions
        
    func onDragChanged(_ translation: CGSize, _ scrollingPoint: CGPoint, _ velocity: CGSize, cancelGesture: () -> ()) {
        let newOffset = offset + scrollingPoint.x * 0.25
        
        if abs(scrollingPoint.x) > 1 {
            dragDirection = scrollingPoint.x
        }
        
        offset = newOffset
    }
    
    func onDragEnded(_ translation: CGSize, _ scrollingPoint: CGPoint, _ velocity: CGSize) {
        withAnimation(.spring) {
            let velocityThreshold: CGFloat = 50
            let offsetThreshold = CalendarDayView.width / 3
            
            var proposedChange = 0
            
            if abs(velocity.width) > velocityThreshold {
                proposedChange = velocity.width > 0 ? -1 : 1
            } else if abs(offset) > offsetThreshold {
                proposedChange = offset > 0 ? -1 : 1
            }
            
            if (dragDirection > 0 && proposedChange > 0) || (dragDirection < 0 && proposedChange < 0) {
                proposedChange = 0
            }
            
            let newIndex = selectedDateIndex + proposedChange
            
            if newIndex >= 0 && newIndex < displayedDates.count {
                selectedDateIndex = newIndex
            }
            
            offset = 0
            dragDirection = 0
        }
    }

}
