//
//  groupAndSortEventsByDate.swift
//  NotchNook
//
//  Created by Igor Marcossi on 09/06/24.
//

import EventKit
import SwiftDate

func groupAndSortEventsByDateAndTime(_ events: [EKEvent]) -> [Date: [EKEvent]] {
    var groupedEvents = [Date: [EKEvent]]()
    let calendar = Calendar.current
    
    for event in events {
        let startDate = calendar.startOfDay(for: event.startDate)
        let endDate = calendar.startOfDay(for: event.endDate)
        
        // Handle multi-day events
        var currentDate = startDate
        while currentDate <= endDate {
            if groupedEvents[currentDate] == nil {
                groupedEvents[currentDate] = []
            }
            groupedEvents[currentDate]?.append(event)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
    }
    
    for (date, events) in groupedEvents {
        groupedEvents[date] = events.sorted { $0.startDate < $1.startDate }
    }
    
    return groupedEvents
}
