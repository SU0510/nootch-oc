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
    var side: ActivitySide
    var activeActivities: Set<LiveActivity>
    var mockEvent: NookEvent?
    @Default(.liveActivitiesSettings) private var liveActivitiesSettings
    @Default(.mediaLiveActivitySettings) private var mediaLiveActivitySettings
    @Default(.calendarLiveActivitySettings) private var calendarLiveActivitySettings
    
    var activityToShow: LiveActivity? {
        if activeActivities.isEmpty { return nil }
        if activeActivities.count == 1, let act = activeActivities.first { return act }
        let orderedActivities = activeActivities.sorted {
            guard let first = activitiesByPriority.firstIndex(of: $0),
                  let second = activitiesByPriority.firstIndex(of: $1) else {
                return false
            }
            return first < second
        }
        switch side {
            case .left: return orderedActivities[1]
            case .right: return orderedActivities[0]
        }
    }
    
    var body: some View {
        Group {
            if let activityToShow {
                switch activityToShow {
                    case .calendar:
                        if let event = mockEvent ?? closestEvent(in: CalendarManager.shared.events)?.getNookEvent() {
                            switch side {
                                case .left: EventIconView(eventTitle: event.title, startDate: event.startDate, endDate: event.endDate, laPrefs: liveActivitiesSettings)
                                case .right: EventTimeView(notes: event.notes, startDate: event.startDate, endDate: event.endDate, prefs: calendarLiveActivitySettings)
                            }
                        }
                    case .media:
                        switch side {
                            case .left: MiniAlbumCoverView(laPrefs: liveActivitiesSettings, prefs: mediaLiveActivitySettings)
                            case .right: AudioWavesView(prefs: mediaLiveActivitySettings)
                        }
                    case .tray:
                        switch side {
                            case .left: TrayIconView()
                            case .right: TrayFilesCountView()
                        }
                    case .updateAvailable:
                        switch side {
                            case .left: UpdateAppIconView(laPrefs: liveActivitiesSettings)
                            case .right: UpdateButtonIconView()
                        }
                }
            }
        }
        .transition(.scaleAndBlur)
    }
    
    enum ActivitySide {
        case left, right
    }
}
