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
    var showEventTimeLapsed = true
    var showWhileInEvent = true
}
