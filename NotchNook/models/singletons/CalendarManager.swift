//
//  CalendarManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 04/06/24.
//

import SwiftUI
import EventKit
import Algorithms
import SwiftDate
import Defaults

@Observable
class CalendarManager {
    
    typealias RequestAccessCompletion = ((Bool, Error?) -> Void)
    
    // MARK: - Properties
        
    static let shared = CalendarManager()
    
    /// Streams of EKEvent instances
    var eventsDatesDict: [Date: [EKEvent]] = [:]
    var events = [EKEvent]() {
        didSet {
            self.scheduleLiveActivities()
            DispatchQueue.main.async {
                self.eventsDatesDict = groupAndSortEventsByDateAndTime(self.events)
            }
        }
    }
    var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    public var availableCalendars: [EKCalendar] {
        eventStore.calendars(for: .event)
    }
    private var selectedCalendars: [EKCalendar] = []
    
    /// An object that accesses the user's calendar and reminder events and supports the scheduling of new events.
    public private(set) var eventStore = EKEventStore()
    
    private var dailyTimer: Timer?
    private var liveActivitiesTimers = [Timer]()
    private var defaultsTask: Task<Void, Never>?
    
    // MARK: - Lifecycle
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(storeChanged(_:)), name: .EKEventStoreChanged, object: eventStore)
        dailyTimer = Timer.scheduledTimer(timeInterval: 86400, target: self, selector: #selector(dailyTask), userInfo: nil, repeats: true)
        defaultsTask = Task { [weak self] in
            for await _ in Defaults.updates(.calendarLiveActivitySettings) {
                self?.scheduleLiveActivities()
            }
        }
        
        loadSelectedCalendars()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .EKEventStoreChanged, object: eventStore)
        dailyTimer?.invalidate()
    }
    
    private func loadSelectedCalendars() {
        let settings = Defaults[.calendarWidgetSettings]
        guard let previouslySelectedCalendars = settings.selectedCalendars else { return }
        selectedCalendars = eventStore.calendars(for: .event).filter {
            previouslySelectedCalendars.contains($0.calendarIdentifier)
        }
    }
    
    @objc private func storeChanged(_ notification: Notification) {
        Task {
            try? await fetchEvents()
        }
    }
    
    @objc private func dailyTask() {
        Task {
            try? await fetchEvents()
        }
    }
    
    public func updateSelectedCalendars(_ calendars: [EKCalendar]) {
        selectedCalendars = calendars
        var settings = Defaults[.calendarWidgetSettings]
        settings.selectedCalendars = calendars.map { $0.calendarIdentifier }
        Defaults[.calendarWidgetSettings] = settings
        Task {
            try? await fetchEvents()
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
            if prefs.onlyEventsWithMeetings, detectMeetings(in: event) == nil { return }
            
            let fireAt = event.startDate - prefs.preEventWindow.minutes
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
    
    // MARK: - Events fetching
    
    /// Core functionality for fetching events within a range, ensuring events are cleared first
    @discardableResult
    public func fetchEvents() async throws -> [EKEvent] {
        do {
            try await accessCalendar()
        } catch {
            print("Calendar access failed: \(error)")
            return []
        }
        
        guard !selectedCalendars.isEmpty else {
            await clearEvents()
            return []
        }
        
        let fetchedEvents = try await fetchEventsInBackground()
        
        await MainActor.run {
            self.events = applyEventFilters(fetchedEvents)
        }
        
        print("Fetched \(fetchedEvents.count) events")
        return fetchedEvents
    }
    
    private func clearEvents() async {
        await MainActor.run {
            self.events = []
            self.eventsDatesDict = [:]
        }
    }
    
    private func fetchEventsInBackground() async throws -> [EKEvent] {
        let settings = Defaults[.calendarWidgetSettings]
        let daysAhead = settings.numberOfDaysAheadToDisplay + 1
        let daysBehind = settings.numberOfDaysBehindToDisplay
        let now = Date()
        
        let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -daysBehind, to: now)!)
        let endDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: daysAhead, to: now)!)
        
        return await Task.detached {
            let pred = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: self.selectedCalendars)
            return self.eventStore.events(matching: pred)
        }.value
    }
    
    private func applyEventFilters(_ events: [EKEvent]) -> [EKEvent] {
        let settings = Defaults[.calendarWidgetSettings]
        let now = Date()
        
        return events
            .filter { event -> Bool in
                if !settings.shouldShowTodayPastEvents {
                    if Calendar.current.isDateInToday(event.startDate) {
                        return event.endDate > now
                    }
                }
                return true
            }
            .filter { event -> Bool in
                if !settings.shouldShowAllDayEvents {
                    return !event.isAllDay || event.isMultiDay
                }
                return true
            }
            .filter { event -> Bool in
                if !settings.shouldShowMultiDayEvents {
                    return !event.isMultiDay
                }
                return true
            }
    }
    
    // MARK: - Private methods
    
    private func accessCalendar() async throws {
        let authorization = try await requestEventStoreAuthorization()
        
        if authorization != .fullAccess {
            throw CalendarManagerError.eventAuthorizationStatus(nil)
        }
    }
    
    private func requestEventStoreAuthorization() async throws -> EKAuthorizationStatus {
        let granted = try await requestCalendarAccess()
        if granted {
            let status = EKEventStore.authorizationStatus(for: .event)
            DispatchQueue.main.async {
                self.authorizationStatus = status
            }
            return status
        } else {
            print("Unable to access calendar")
            throw CalendarManagerError.unableToAccessCalendar
        }
    }
    
    private func requestCalendarAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(throwing: CalendarManagerError.unableToAccessCalendar)
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
