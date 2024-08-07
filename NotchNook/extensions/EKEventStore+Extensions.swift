//
//  EKEventStore+Extensions.swift
//  NotchNook
//
//  Created by Lori Montenegro on 24/07/24.
//

import EventKit

extension EKEventStore {
    
    public func createEvent(
        title: String,
        startDate: Date,
        endDate: Date?,
        calendar: EKCalendar,
        span: EKSpan = .thisEvent,
        isAllDay: Bool = false
    ) async throws -> EKEvent {
        let event = EKEvent(eventStore: self)
        event.calendar = calendar
        event.title = title
        event.isAllDay = isAllDay
        event.startDate = startDate
        event.endDate = endDate
        try save(event, span: span, commit: true)
        return event
    }
    
    public func deleteEvent(identifier: String, span: EKSpan = .thisEvent) throws {
        guard let event = fetchEvent(identifier: identifier) else {
            throw CalendarManagerError.invalidEvent
        }
        
        try remove(event, span: span, commit: true)
    }
        
    public func calendarForApp() -> EKCalendar? {
        guard let calendarTitle = CalendarManager.calendarTitle else {
            print("App name is nil, please config with `CalendarManager.configureWithAppName` in AppDelegate")
            return nil
        }
                
        if let calendar = calendars(for: .event).first(where: { $0.title == calendarTitle }) {
            return calendar
        }
        else {
            let newCalendar = EKCalendar(for: .event, eventStore: self)
            newCalendar.title = calendarTitle
            newCalendar.source = defaultCalendarForNewEvents?.source
            newCalendar.cgColor = .init(red: 1, green: 0, blue: 0, alpha: 1)
            try? saveCalendar(newCalendar, commit: true)
            return newCalendar
        }
    }
    
    func fetchEvent(identifier: String) -> EKEvent? {
        event(withIdentifier: identifier)
    }
}
