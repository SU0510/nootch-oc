//
//  LiveActivityView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 15/06/24.
//

import SwiftUI
import Defaults

private var activitiesByPriority: [LiveActivity] = [.shelf, .calendar, .media]

struct LiveActivityView: View {
    var side: ActivitySide
    var activeActivities: Set<LiveActivity>
    @Default(.liveActivitiesSettings) private var liveActivitiesSettings
    @Default(.mediaLiveActivitySettings) private var mediaLiveActivitySettings
    @Default(.calendarLiveActivitySettings) private var calendarLiveActivitySettings
    
    var activityToShow: LiveActivity? {
        let activeEnabledActivities = activeActivities.filter { liveActivitiesSettings.enabledLiveActivities.contains($0) }
        if activeEnabledActivities.isEmpty { return nil }
        if activeEnabledActivities.count == 1, let act = activeEnabledActivities.first { return act }
        let orderedActivities = activeEnabledActivities.sorted {
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
                        if let closestEvent = closestEvent(in: CalendarManager.shared.events) {
                            switch side {
                                case .left: EventIconView(event: closestEvent, laPrefs: liveActivitiesSettings)
                                case .right: EventTimeView(event: closestEvent, prefs: calendarLiveActivitySettings)
                            }
                        }
                    case .media:
                        switch side {
                            case .left: MiniAlbumCoverView(laPrefs: liveActivitiesSettings, prefs: mediaLiveActivitySettings)
                            case .right: AudioWavesView(prefs: mediaLiveActivitySettings)
                        }
                    case .shelf:
                        switch side {
                            case .left: ShelfIconView()
                            case .right: ShelfFilesCountView()
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
