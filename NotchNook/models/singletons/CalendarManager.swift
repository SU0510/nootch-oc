//
//  CalendarManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 04/06/24.
//

import Foundation
import SwiftUI
import EventKit
import Algorithms
import SwiftDate
import Defaults
import SwiftDate

typealias RequestAccessCompletion = ((Bool, Error?) -> Void)

/// CalendarManagerError definition
public enum CalendarManagerError: Error, LocalizedError {
    case mapFromError(Error)
    case unableToAccessCalendar
    case eventAuthorizationStatus(EKAuthorizationStatus? = nil)
    case invalidEvent
    
    var localizedDescription: String {
        switch self {
            case .invalidEvent: return "Invalid event"
            case .unableToAccessCalendar: return "Unable to access calendar"
            case let .mapFromError(error): return error.localizedDescription
            case let .eventAuthorizationStatus(status):
                if let status = status {
                    return "Failed to authorize event permission, status: \(status)"
                } else {
                    return "Failed to authorize event permission"
                }
        }
    }
}

@MainActor
class CalendarManager: ObservableObject {
    
    // MARK: - Properties
    
    /// Streams of EKEvent instances
    @Published var eventsDatesDict: [Date: [EKEvent]] = [:]
    public var events = [EKEvent]() {
        didSet {
            self.scheduleLiveActivities()
            self.eventsDatesDict = groupAndSortEventsByDateAndTime(events)
        }
    }
    
    /// The calendar’s title.
    public static var appName: String?
    
    /// Event store: An object that accesses the user’s calendar and reminder events and supports the scheduling of new events.
    public private(set) var eventStore = EKEventStore()
    
    /// Returns calendar object from event kit
    public var defaultCalendar: EKCalendar? {
        eventStore.calendarForApp()
    }
    
    private var dailyTimer: Timer?
    private var liveActivitiesTimers = [Timer]()
    private var defaultsTask: Task<Void, Never>?
    
    // MARK: Lifecycle
    
    /// Shared `CalendarManager` singleton
    public static let shared = CalendarManager()
    
    /// Configuration point
    /// - Parameter appName: the calendar's title
    public static func configureWithAppName(_ appName: String) {
        self.appName = appName
    }
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(storeChanged(_:)), name: .EKEventStoreChanged, object: eventStore)
        print("Added observer for EKEventStoreChanged")
        dailyTimer = Timer.scheduledTimer(timeInterval: 86400, target: self, selector: #selector(dailyTask), userInfo: nil, repeats: true)
        defaultsTask = Task { [weak self] in
            for await _ in Defaults.updates(.calendarLiveActivitySettings) {
                self?.scheduleLiveActivities()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .EKEventStoreChanged, object: eventStore)
        print("Removed observer for EKEventStoreChanged")
        dailyTimer?.invalidate()
    }

    
    @objc private func storeChanged(_ notification: Notification) {
        Task {
            try? await fetchEventsForDaysOffset(CalendarWidgetView.showingDatesCount)
        }
    }
    
    @objc private func dailyTask() {
        Task {
            try? await fetchEventsForDaysOffset(CalendarWidgetView.showingDatesCount)
        }
    }
    
    func scheduleLiveActivities() {
        let prefs = Defaults[.calendarLiveActivitySettings]
        liveActivitiesTimers.forEach { timer in
            timer.invalidate()
        }
        liveActivitiesTimers = []
        
        var addedLiveActivity = false
        
        func addLiveActivity(event: EKEvent) {
            addedLiveActivity = true
            Task { await MainActor.run {
                ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.calendar)
            } }
        }
        
        events.forEach { event in
            let now = Date()
            if event.endDate < now { return }
            if prefs.onlyEventsWithMeetings, detectMeetings(event.notes ?? "") == nil { return }
            
            let fireAt = event.startDate - prefs.minutesBeforeEvent.minutes
            let willHappen = fireAt > now
            let isHappening = !willHappen && event.endDate > now
            
            if isHappening {
                addLiveActivity(event: event)
            } else if willHappen {
                let fireIn = fireAt.timeIntervalSince1970 - now.timeIntervalSince1970
                liveActivitiesTimers.append(Timer.scheduledTimer(withTimeInterval: fireIn, repeats: false) { _ in
                    addLiveActivity(event: event)
                })
            }
        }
        if !addedLiveActivity {
            ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.calendar)
        }
    }
    
    // MARK: - Flow
    
    /// Request event store authorization
    /// - Returns: EKAuthorizationStatus enum
    public func requestEventStoreAuthorization() async throws -> EKAuthorizationStatus {
        let granted = try await requestCalendarAccess()
        print("Calendar access granted: \(granted)")
        if granted {
            let authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            print("Authorization status: \(authorizationStatus.rawValue)")
            return authorizationStatus
        } else {
            print("Unable to access calendar")
            throw CalendarManagerError.unableToAccessCalendar
        }
    }
    
    // MARK: - CRUD
    
    /// Create an event
    /// - Parameters:
    ///   - title: title of the event
    ///   - startDate: event's start date
    ///   - endDate: event's end date
    ///   - span: event's span
    ///   - isAllDay: is all day event
    /// - Returns: created event
#if os(iOS) || os(macOS)
    public func createEvent(
        _ title: String,
        startDate: Date,
        endDate: Date?,
        span: EKSpan = .thisEvent,
        isAllDay: Bool = false,
        calendar: EKCalendar? = nil
    ) async throws -> EKEvent {
        var theCalendar: EKCalendar
        if let calendar = calendar {
            theCalendar = calendar
        } else {
            theCalendar = try await accessCalendar()
        }
        
        let createdEvent = try await self.eventStore.createEvent(title: title, startDate: startDate, endDate: endDate, calendar: theCalendar, span: span, isAllDay: isAllDay)
        return createdEvent
    }
#endif
    
    /// Delete an event
    /// - Parameters:
    ///   - identifier: event identifier
    ///   - span: even't span
#if os(iOS) || os(macOS)
    public func deleteEvent(
        identifier: String,
        span: EKSpan = .thisEvent
    ) async throws {
        try await accessCalendar()
        try self.eventStore.deleteEvent(identifier: identifier, span: span)
    }
#endif
    
    // MARK: - Fetch Events
    @discardableResult
    public func fetchEventsForDaysOffset(_ days: Int, calendar: Calendar = .autoupdatingCurrent) async throws {
        let offset = days / 2
        let today = Date()
        try await fetchEvents(
            startDate: today - offset.days,
            endDate: today + offset.days
        )
    }
    
    /// Fetch events for today
    /// - Parameter completion: completion handler
    /// - Parameter filterCalendarIDs: filterable Calendar IDs
    @discardableResult
    public func fetchEventsForToday(
        filterCalendarIDs: [String] = [],
        calendar: Calendar = .autoupdatingCurrent
    ) async throws -> [EKEvent] {
        let today = Date()
        return try await fetchEvents(startDate: today.startOfDay(calendar: calendar), endDate: today.endOfDay(calendar: calendar), filterCalendarIDs: filterCalendarIDs)
    }
    
    /// Fetch events for a specific day
    /// - Parameters:
    ///   - date: day to fetch events from
    ///   - completion: completion handler
    ///   - filterCalendarIDs: filterable Calendar IDs
    /// Returns: events
    @discardableResult
    public func fetchEvents(
        for date: Date,
        filterCalendarIDs: [String] = [],
        calendar: Calendar = .autoupdatingCurrent
    ) async throws -> [EKEvent] {
        try await fetchEvents(startDate: date.startOfDay(calendar: calendar), endDate: date.endOfDay(calendar: calendar), filterCalendarIDs: filterCalendarIDs)
    }
    
    /// Fetch events for a specific day
    /// - Parameters:
    ///   - date: day to fetch events from
    ///   - completion: completion handler
    ///   - startDate: event start date
    ///   - filterCalendarIDs: filterable Calendar IDs
    /// Returns: events
    @discardableResult
    public func fetchEventsRangeUntilEndOfDay(
        from startDate: Date,
        filterCalendarIDs: [String] = [],
        calendar: Calendar = .autoupdatingCurrent
    ) async throws -> [EKEvent] {
        try await fetchEvents(startDate: startDate, endDate: startDate.endOfDay(calendar: calendar), filterCalendarIDs: filterCalendarIDs)
    }
    
    /// Fetch events from date range
    /// - Parameters:
    ///   - startDate: start date range
    ///   - endDate: end date range
    ///   - completion: completion handler
    ///   - filterCalendarIDs: filterable Calendar IDs
    /// Returns: events
    @discardableResult
    public func fetchEvents(
        startDate: Date,
        endDate: Date,
        filterCalendarIDs: [String] = []
    ) async throws -> [EKEvent] {
        print("Fetching events from \(startDate) to \(endDate)")

        let authorization = try await requestEventStoreAuthorization()
        guard authorization == .fullAccess else {
            print("Authorization status is not fullAccess: \(authorization.rawValue)")
            throw CalendarManagerError.eventAuthorizationStatus(nil)
        }

        let calendars = self.eventStore.calendars(for: .event).filter { calendar in
            if filterCalendarIDs.isEmpty { return true }
            return filterCalendarIDs.contains(calendar.calendarIdentifier)
        }

        let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = self.eventStore.events(matching: predicate).uniqued(on: \.eventIdentifier)

        await MainActor.run {
            for event in events {
                let date = Calendar.current.startOfDay(for: event.startDate)
                if self.eventsDatesDict[date] == nil {
                    self.eventsDatesDict[date] = []
                }
                self.eventsDatesDict[date]?.append(event)
            }
            print("Updated eventsDatesDict: \(self.eventsDatesDict)")
        }

        print("Fetched \(events.count) events")
        return events
    }

    
    public func fetchEvents(from startDate: Date = .now) async throws {
        guard let endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate) else {
            throw CalendarManagerError.invalidEvent
        }
        try await fetchEvents(startDate: startDate, endDate: endDate)
    }
    
    // MARK: Private
    
    /// Request access to calendar
    /// - Returns: calendar object
    @discardableResult
    private func accessCalendar() async throws -> EKCalendar {
        let authorization = try await requestEventStoreAuthorization()
        
        guard authorization == .fullAccess else {
            throw CalendarManagerError.eventAuthorizationStatus(nil)
        }
        
        guard let calendar = eventStore.calendarForApp() else {
            throw CalendarManagerError.unableToAccessCalendar
        }
        
        return calendar
    }
    
    
    private func requestCalendarAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                print("Self is nil in requestCalendarAccess")
                return
            }
            let completion: RequestAccessCompletion = { granted, error in
                if let error {
                    print("Error requesting calendar access: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    print("Calendar access granted: \(granted)")
                    continuation.resume(returning: granted)
                }
            }
            
            self.eventStore.requestFullAccessToEvents(completion: completion)
        }
    }

    
}

extension EKEventStore {
    
    // MARK: - CRUD
    
    /// Create an event
    /// - Parameters:
    ///   - title: title of the event
    ///   - startDate: event's start date
    ///   - endDate: event's end date
    ///   - calendar: calendar instance
    ///   - span: event's span
    ///   - isAllDay: is all day event
    /// - Returns: created event
#if os(iOS) || os(macOS)
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
#endif
    
    /// Delete event
    /// - Parameters:
    ///   - identifier: event identifier
    ///   - span: event's span
#if os(iOS) || os(macOS)
    public func deleteEvent(
        identifier: String,
        span: EKSpan = .thisEvent
    ) throws {
        guard let event = fetchEvent(identifier: identifier) else {
            throw CalendarManagerError.invalidEvent
        }
        
        try remove(event, span: span, commit: true)
    }
#endif
    
    // MARK: - Fetch
    
    /// Calendar for current AppName
    /// - Returns: App calendar
    /// - Parameter calendarColor: default new calendar color
    @MainActor public func calendarForApp(calendarColor: CGColor = .init(red: 1, green: 0, blue: 0, alpha: 1)) -> EKCalendar? {
        guard let appName = CalendarManager.appName else {
#if DEBUG
            print("App name is nil, please config with `CalendarManager.configureWithAppName` in AppDelegate")
#endif
            return nil
        }
        
        let calendars = self.calendars(for: .event)
        
        if let clendar = calendars.first(where: { $0.title == appName }) {
            return clendar
        }
        else {
#if os(iOS) || os(macOS)
            let newClendar = EKCalendar(for: .event, eventStore: self)
            newClendar.title = appName
            newClendar.source = defaultCalendarForNewEvents?.source
            newClendar.cgColor = .init(red: 1, green: 0, blue: 0, alpha: 1)
            try? saveCalendar(newClendar, commit: true)
            return newClendar
#else
            return nil
#endif
        }
    }
    
    /// Fetch an EKEvent instance with given identifier
    /// - Parameter identifier: event identifier
    /// - Returns: an EKEvent instance with given identifier
    func fetchEvent(identifier: String) -> EKEvent? {
        event(withIdentifier: identifier)
    }
}

extension Date {
    func startOfDay(calendar: Calendar = .autoupdatingCurrent) -> Date {
        calendar.startOfDay(for: self)
    }
    
    func endOfDay(calendar: Calendar = .autoupdatingCurrent) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        // swiftlint:disable:next force_unwrapping
        return calendar.date(byAdding: components, to: startOfDay(calendar: calendar))!
    }
}
