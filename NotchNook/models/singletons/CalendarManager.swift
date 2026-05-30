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
class CalendarManager: @unchecked Sendable {
    
    typealias RequestAccessCompletion = (@Sendable (Bool, Error?) -> Void)
    
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
        dailyTimer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.dailyTask()
        }
        defaultsTask = Task { [weak self] in
            for await _ in Defaults.updates(.calendarLiveActivitySettings) {
                self?.scheduleLiveActivities()
            }
        }
        
        loadSelectedCalendars()
    }
    
    deinit {
        dailyTimer?.invalidate()
        liveActivitiesTimers.forEach { $0.invalidate() }
        liveActivitiesTimers.removeAll()
        
        defaultsTask?.cancel()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    private func loadSelectedCalendars() {
        let settings = Defaults[.calendarWidgetSettings]
        let availableCalendars = eventStore.calendars(for: .event)
        
        if settings.selectedCalendars == nil {
            selectedCalendars = availableCalendars
            var updatedSettings = settings
            updatedSettings.selectedCalendars = availableCalendars.map { $0.calendarIdentifier }
            Defaults[.calendarWidgetSettings] = updatedSettings
            return
        }
        
        let savedIdentifiers = settings.selectedCalendars ?? []
        let matchedCalendars = availableCalendars.filter { savedIdentifiers.contains($0.calendarIdentifier) }
        
        // If calendars were merged/removed and no saved identifiers match anymore,
        // fall back to showing all available calendars to avoid empty results.
        if matchedCalendars.isEmpty && !savedIdentifiers.isEmpty {
            selectedCalendars = availableCalendars
            var updatedSettings = settings
            updatedSettings.selectedCalendars = availableCalendars.map { $0.calendarIdentifier }
            Defaults[.calendarWidgetSettings] = updatedSettings
            return
        }
        
        selectedCalendars = matchedCalendars
        
        // Clean up any stale identifiers to keep settings in sync with the store.
        if matchedCalendars.count != savedIdentifiers.count {
            var updatedSettings = settings
            updatedSettings.selectedCalendars = matchedCalendars.map { $0.calendarIdentifier }
            Defaults[.calendarWidgetSettings] = updatedSettings
        }
    }
    
    @objc private func storeChanged(_ notification: Notification) {
        Task { @MainActor in
            eventStore.reset()
            loadSelectedCalendars()
            _ = try? await fetchEvents()
        }
    }
    
    private func dailyTask() {
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
        liveActivitiesTimers.forEach { $0.invalidate() }
        liveActivitiesTimers.removeAll()
        
        let prefs = Defaults[.calendarLiveActivitySettings]
        
        var addedLiveActivity = false
        
        func manageLiveActivity(event: EKEvent) {
            guard shouldShowCalendarActivity(event: event, settings: prefs) else { return }
            
            addedLiveActivity = true
            
            // Add live activity
            Task {
                await MainActor.run {
                    ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.calendar)
                }
            }
            
            // Schedule removal for when the event ends
            let now = Date()
            let removeIn = event.endDate.timeIntervalSince(now)
            
            if removeIn > 0 {
                let removeTimer = Timer.scheduledTimer(withTimeInterval: removeIn, repeats: false) { _ in
                    Task { @MainActor in
                        ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.calendar)
                    }
                }
                liveActivitiesTimers.append(removeTimer)
            }
            
            // Handle periodic appearance
            switch prefs.appearanceMode {
                case .constant:
                    // Keep live activity constantly visible
                    return
                    
                case .periodic(let interval):
                    func triggerActivity() {
                        Task { @MainActor in
                            if shouldShowCalendarActivity(event: event, settings: prefs) {
                                ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.calendar)
                                
                                // Synchronous hide after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.calendar)
                                }
                            }
                        }
                    }
                    
                    triggerActivity()
                    
                    let periodicTimer = Timer.scheduledTimer(withTimeInterval: interval + 3.0, repeats: true) { _ in
                        triggerActivity()
                    }
                    liveActivitiesTimers.append(periodicTimer)
            }
        }
        
        events.forEach { event in
            let now = Date()
            if event.endDate < now { return }
            
            let fireAt = event.startDate - prefs.preEventWindow.minutes
            let willHappen = fireAt > now
            let isHappening = !willHappen && event.endDate > now
            
            if isHappening {
                manageLiveActivity(event: event)
            } else if willHappen {
                let fireIn = fireAt.timeIntervalSince1970 - now.timeIntervalSince1970
                let timer = Timer.scheduledTimer(withTimeInterval: fireIn, repeats: false) { _ in
                    manageLiveActivity(event: event)
                }
                liveActivitiesTimers.append(timer)
            }
        }
        
        // Schedule a one-shot fetch 1s after each currently-happening event ends,
        // so the events array is trimmed promptly rather than waiting up to 24h for the daily timer.
        let now = Date()
        events.forEach { event in
            guard !event.isAllDay, event.startDate <= now, event.endDate > now else { return }
            let fireIn = event.endDate.timeIntervalSince(now) + 1
            let refreshTimer = Timer.scheduledTimer(withTimeInterval: fireIn, repeats: false) { [weak self] _ in
                Task { try? await self?.fetchEvents() }
            }
            liveActivitiesTimers.append(refreshTimer)
        }
        
        Task { @MainActor in
            if !addedLiveActivity {
                ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.calendar)
            }
        }
    }
    
    func shouldShowCalendarActivity(event: EKEvent, settings: CalendarLiveActivitySettings) -> Bool {
        guard !event.isAllDay else { return false }
        
        if settings.onlyEventsWithMeetings, detectMeetings(in: event) == nil { return false }
        
        let now = Date()
        let timeUntilEventStart = event.startDate.timeIntervalSince(now)
        let timeUntilEventEnd = event.endDate.timeIntervalSince(now)
        
        let isEventInProgress = timeUntilEventStart <= 0 && timeUntilEventEnd > 0
        let isWithinPreEventWindow = !isEventInProgress &&
        timeUntilEventStart <= Double(settings.preEventWindow * 60)
        
        let shouldShowDuringEvent = isEventInProgress && settings.showEventTimeLapsed
        
        return isWithinPreEventWindow || shouldShowDuringEvent
    }
    
    func shouldShowEventTimeView(event: EKEvent, settings: CalendarLiveActivitySettings) -> Bool {
        guard let closestEvent = closestEvent(settings: settings) else { return true }
        return closestEvent.startDate < Date() ? settings.showEventTimeLapsed : true
    }
    
    func closestEvent(settings: CalendarLiveActivitySettings) -> EKEvent? {
        let now = Date()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        
        let filteredEvents = events.filter { event in
            !event.isAllDay &&
            event.startDate >= yesterday &&
            event.startDate <= tomorrow &&
            event.endDate > now
        }
        
        // Check for events within pre-event window
        let preEventWindowEvents = filteredEvents.filter { event in
            let timeUntilEventStart = event.startDate.timeIntervalSince(now)
            return timeUntilEventStart > 0 && timeUntilEventStart <= Double(settings.preEventWindow * 60)
        }
        
        // If there are events within pre-event window, return the closest one
        if let closestPreEventWindowEvent = preEventWindowEvents.min(by: { $0.startDate < $1.startDate }) {
            return closestPreEventWindowEvent
        }
        
        return filteredEvents.min(by: { abs($0.startDate.timeIntervalSince(now)) < abs($1.startDate.timeIntervalSince(now)) })
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
        
        let now = Date()
        let settings = Defaults[.calendarWidgetSettings]
        let range = makeFetchRange(settings: settings, now: now)
        let fetchedEvents = try await fetchEventsInBackground(range: range)
        
        await MainActor.run {
            let filtered = applyEventFilters(fetchedEvents)
            self.events = filtered
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
    
    private func fetchEventsInBackground(range: (start: Date, end: Date)) async throws -> [EKEvent] {
        return await MainActor.run {
            let pred = self.eventStore.predicateForEvents(withStart: range.start, end: range.end, calendars: self.selectedCalendars)
            return self.eventStore.events(matching: pred)
        }
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
    
    private func makeFetchRange(settings: CalendarWidgetSettings, now: Date) -> (start: Date, end: Date) {
        let daysAhead = settings.numberOfDaysAheadToDisplay + 1
        let daysBehind = settings.numberOfDaysBehindToDisplay
        let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -daysBehind, to: now)!)
        let endDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: daysAhead, to: now)!)
        return (startDate, endDate)
    }
}
