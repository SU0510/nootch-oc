//
//  LiveActivitiesSettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import Foundation

struct LiveActivitiesSettings: Preferences {
    var enabled = true
    var inactivityTimeoutInSecs: Double = 10
    var enabledLiveActivities: Set<LiveActivity> = [.shelf, .media]
    var interactive = true
    var enableQuickPeak = true
}
