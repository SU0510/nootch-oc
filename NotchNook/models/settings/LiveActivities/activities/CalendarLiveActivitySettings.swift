//
//  CalendarLiveActivitySettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 13/06/24.
//

import Foundation

struct CalendarLiveActivitySettings: Preferences {
    var preEventWindow: Int = 15
    var onlyEventsWithMeetings = false
    var showEventTimeLapsed = false
    
    enum AppearanceMode: Equatable, Hashable, Codable {
        case constant
        case periodic(interval: TimeInterval)
    }
    var appearanceMode: AppearanceMode = .constant
}
