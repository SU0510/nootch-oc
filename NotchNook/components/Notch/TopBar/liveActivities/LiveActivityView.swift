//
//  LiveActivityView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 15/06/24.
//

import SwiftUI
import Defaults
import EventKit

private var activitiesByPriority: [LiveActivity] = [.bluetoothDevice, .batteryVisualizer, .tray, .calendar, .updateAvailable, .media]

struct LiveActivityView: View {
    
    enum ActivitySide {
        case left, right
    }
    var side: ActivitySide
    var activeActivities: Set<LiveActivity>
    
    @Environment(\.liveActivitiesSettings) private var liveActivitiesSettings
    @Environment(\.mediaLiveActivitySettings) private var mediaLiveActivitySettings
    @Environment(\.calendarLiveActivitySettings) private var calendarLiveActivitySettings
    
    @State private var batteryStatus: PowerMonitor.BatteryStatus?
    
    var activitiesManager = ActiveLiveActivitiesManager.shared
    
    // MARK: Computed properties
    
    private var eventStarted: Bool {
        guard let event = closestEvent() else { return false }
        return event.startDate < Date()
    }
    
    private var shouldShowCalendarActivity: Bool {
        guard let event = closestEvent() else { return false }
        let now = Date()
        let timeUntilEventStart = event.startDate.timeIntervalSince(now)
        let timeUntilEventEnd = event.endDate.timeIntervalSince(now)
        let isEventInProgress = timeUntilEventStart <= 0 && timeUntilEventEnd > 0
        
        let isWithinPreEventWindow = !isEventInProgress && timeUntilEventStart <= Double(calendarLiveActivitySettings.preEventWindow * 60)
        
        let shouldShowDuringEvent = isEventInProgress && calendarLiveActivitySettings.showWhileInEvent
        
        return isWithinPreEventWindow || shouldShowDuringEvent
    }
    
    private var shouldShowEventTimeView: Bool {
        eventStarted ? calendarLiveActivitySettings.showEventTimeLapsed : true
    }
    
    private var orderedActivities: [LiveActivity] {
        activeActivities.sorted {
            guard let first = activitiesByPriority.firstIndex(of: $0),
                  let second = activitiesByPriority.firstIndex(of: $1) else {
                return false
            }
            return first < second
        }
    }
    
    private var isFirstActivityCalendar: Bool {
        orderedActivities.first == .calendar && shouldShowCalendarActivity && orderedActivities.count == 1
    }
    
    private var shouldEnableQuickPeekForTime: Bool {
        !isFirstActivityCalendar && liveActivitiesSettings.enableQuickPeek
    }
    
    var activityToShow: LiveActivity? {
        if activeActivities.isEmpty { return nil }

        if orderedActivities.first == .calendar {
            if !shouldShowCalendarActivity {
                return orderedActivities.count > 1 ? orderedActivities[1] : nil
            }
        } else if orderedActivities.first == .batteryVisualizer {
            if batteryStatus == nil {
                return orderedActivities.count > 1 ? orderedActivities[1] : nil
            }
        }
        
        return orderedActivities.first
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let activityToShow {
                switch activityToShow {
                    case .calendar:
                        if let event = closestEvent() {
                            switch side {
                                case .left:
                                    EventIconView(eventTitle: event.title, startDate: event.startDate, endDate: event.endDate, enableQuickPeek: liveActivitiesSettings.enableQuickPeek)
                                case .right:
                                    if shouldShowEventTimeView {
                                        EventTimeView(event: event, startDate: event.startDate, endDate: event.endDate)
                                            .environment(\.enableQuickPeek, shouldEnableQuickPeekForTime)
                                    } else {
                                        Spacer()
                                    }
                            }
                        }
                        
                    case .media:
                        switch side {
                            case .left:
                                MiniAlbumCoverView(enableQuickPeek: liveActivitiesSettings.enableQuickPeek,
                                                   quickPeekEvent: liveActivitiesSettings.quickPeekEvent,
                                                   albumCornerRadius: mediaLiveActivitySettings.albumCornerRadius)
                            case .right:
                                AudioAnimationView()
                        }
                        
                    case .tray:
                        switch side {
                            case .left:
                                LiveActivityIconView(liveActivity: .tray)
                            case .right:
                                TrayFilesCountView()
                        }
                        
                    case .updateAvailable:
                        switch side {
                            case .left:
                                UpdateAppIconView(enableQuickPeek: liveActivitiesSettings.enableQuickPeek)
                            case .right:
                                UpdateButtonIconView()
                        }
                        
                    case .bluetoothDevice:
                        switch side {
                            case .left:
                                BluetoothDeviceIconView()
                            case .right:
                                BluetoothConnectDisconnectView()
                        }
                        
                    case .batteryVisualizer:
                        switch side {
                            case .left:
                                BatteryIconView(batteryStatus: batteryStatus)
                            case .right:
                                TimeLeftView(batteryStatus: batteryStatus)
                        }
                }
            }
        }
        .transition(.scaleAndBlur)
        .onChange(of: PowerMonitor.shared.status) { _, status in
            batteryStatus = status
        }
    }
    
    private func closestEvent() -> EKEvent? {
        let events = CalendarManager.shared.events
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
            return timeUntilEventStart > 0 && timeUntilEventStart <= Double(calendarLiveActivitySettings.preEventWindow * 60)
        }
        
        // If there are events within pre-event window, return the closest one
        if let closestPreEventWindowEvent = preEventWindowEvents.min(by: { $0.startDate < $1.startDate }) {
            return closestPreEventWindowEvent
        }
        
        return filteredEvents.min(by: { abs($0.startDate.timeIntervalSince(now)) < abs($1.startDate.timeIntervalSince(now)) })
    }

}
