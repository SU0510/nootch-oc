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

    @Environment(\.liveActivitiesSettings) private var liveActivitiesSettings
    @Environment(\.mediaLiveActivitySettings) private var mediaLiveActivitySettings
    @Environment(\.calendarLiveActivitySettings) private var calendarLiveActivitySettings
    
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
                        if let event = closestEvent(in: CalendarManager.shared.events) {
                            switch side {
                                case .left: 
                                    EventIconView(eventTitle: event.title, startDate: event.startDate, endDate: event.endDate, enableQuickPeek: liveActivitiesSettings.enableQuickPeek)
                                case .right: 
                                    EventTimeView(event: event, startDate: event.startDate, endDate: event.endDate)
                            }
                        }
                    case .media:
                        switch side {
                            case .left: MiniAlbumCoverView(enableQuickPeek: liveActivitiesSettings.enableQuickPeek, albumCornerRadius: mediaLiveActivitySettings.albumCornerRadius)
                            case .right: AudioWavesView()
                        }
                    case .tray:
                        switch side {
                            case .left: TrayIconView()
                            case .right: TrayFilesCountView()
                        }
                    case .updateAvailable:
                        switch side {
                            case .left: UpdateAppIconView(enableQuickPeek: liveActivitiesSettings.enableQuickPeek)
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
