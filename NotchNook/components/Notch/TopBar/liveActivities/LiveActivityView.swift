//
//  LiveActivityView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 15/06/24.
//

import SwiftUI
import Defaults

private var activitiesByPriority: [LiveActivity] = [.tray, .calendar, .updateAvailable, .media]

struct LiveActivityView: View {
    
    enum ActivitySide {
        case left, right
    }
    var side: ActivitySide
    var activeActivities: Set<LiveActivity>

    @Environment(\.liveActivitiesSettings) private var liveActivitiesSettings
    @Environment(\.mediaLiveActivitySettings) private var mediaLiveActivitySettings
    @Environment(\.calendarLiveActivitySettings) private var calendarLiveActivitySettings
    
    @StateObject var activitiesManager = ActiveLiveActivitiesManager.shared
    
    // MARK: Computed properties
    
    private var eventStarted: Bool {
        guard let event = closestEvent(in: CalendarManager.shared.events) else { return false }
        return event.startDate < Date()
    }
    
    private var shouldShowCalendarActivity: Bool {
        eventStarted ? calendarLiveActivitySettings.showWhileInEvent : true
    }
    
    private var shouldShowEventTimeView: Bool {
        eventStarted ? calendarLiveActivitySettings.showEventTimeLapsed : true
    }
        
    var activityToShow: LiveActivity? {
        if activeActivities.isEmpty { return nil }
        
        if activeActivities.count == 1, let firstActivity = activeActivities.first {
            return firstActivity == .calendar ? (shouldShowCalendarActivity ? .calendar : nil) : firstActivity
        }
        
        let orderedActivities = activeActivities.sorted {
            guard let first = activitiesByPriority.firstIndex(of: $0),
                  let second = activitiesByPriority.firstIndex(of: $1) else {
                return false
            }
            return first < second
        }
        
        if orderedActivities.first == .calendar {
            if !shouldShowCalendarActivity {
                return orderedActivities.count > 1 ? orderedActivities[1] : nil
            }
        }
        
        switch side {
            case .left:
                return orderedActivities.count > 1 ? orderedActivities[1] : orderedActivities.first
            case .right:
                return orderedActivities.first
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let activityToShow {
                switch activityToShow {
                    case .calendar:
                        if let event = closestEvent(in: CalendarManager.shared.events) {
                            switch side {
                                case .left:
                                    EventIconView(eventTitle: event.title, startDate: event.startDate, endDate: event.endDate, enableQuickPeek: liveActivitiesSettings.enableQuickPeek)
                                case .right:
                                    if shouldShowEventTimeView {
                                        EventTimeView(event: event, startDate: event.startDate, endDate: event.endDate)
                                    } else {
                                        Spacer()
                                    }
                            }
                        }
                        
                    case .media:
                        switch side {
                            case .left:
                                MiniAlbumCoverView(enableQuickPeek: liveActivitiesSettings.enableQuickPeek, albumCornerRadius: mediaLiveActivitySettings.albumCornerRadius)
                            case .right:
                                AudioWavesView()
                        }
                        
                    case .tray:
                        switch side {
                            case .left: 
                                TrayIconView()
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
                }
            }
        }
        .onChange(of: activitiesManager.activeLiveActivities) { _ in
            withAnimation {
                // Force view update
            }
        }
        .transition(.scaleAndBlur)
    }
}
