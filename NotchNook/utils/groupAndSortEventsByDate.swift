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
        
        groupedEvents[startDate, default: []].append(event)
    }
    
    for (date, events) in groupedEvents {
        groupedEvents[date] = events.sorted {
            if $0.startDate != $1.startDate {
                return $0.startDate < $1.startDate
            } else {
                return $0.endDate < $1.endDate
            }
        }
    }
    
    return groupedEvents
}
