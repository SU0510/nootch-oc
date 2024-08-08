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
        
    static let numberOfDaysToDisplay = 90
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
    
    public static var calendarTitle: String?
    
    /// An object that accesses the user's calendar and reminder events and supports the scheduling of new events.
    public private(set) var eventStore = EKEventStore()
    
    /// Returns calendar object from event kit
    public var defaultCalendar: EKCalendar? {
        eventStore.calendarForApp()
    }
    
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
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .EKEventStoreChanged, object: eventStore)
        dailyTimer?.invalidate()
    }
    
    /// Configuration point
    /// - Parameter appName: the calendar's title
    public static func configureWithAppName(_ appName: String) {
        self.calendarTitle = appName
    }
    
    @objc private func storeChanged(_ notification: Notification) {
        Task {
            try? await fetchEventsForDaysOffset(Self.numberOfDaysToDisplay)
        }
    }
    
    @objc private func dailyTask() {
        Task {
            try? await fetchEventsForDaysOffset(Self.numberOfDaysToDisplay)
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
    
    public func fetchEventsForDaysOffset(_ days: Int, calendar: Calendar = .autoupdatingCurrent) async throws {
        let offset = days / 2
        let today = Date()
        try await fetchEvents(
            startDate: today - offset.days,
            endDate: today + offset.days
        )
    }
    
    /// Core functionality for fetching events within a range, ensuring events are cleared first
    @discardableResult
    public func fetchEvents(startDate: Date, endDate: Date, filterCalendarIDs: [String] = []) async throws -> [EKEvent] {
        _ = try await accessCalendar()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let calendars = self.eventStore.calendars(for: .event)
            
            let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
            
            let fetchedEvents = self.eventStore.events(matching: predicate)
            self.events = fetchedEvents
        }

        print("Fetched \(self.events.count) events")
        return self.events
    }
    
    // MARK: - Private methods
    
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
