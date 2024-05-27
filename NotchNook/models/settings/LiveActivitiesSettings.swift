//
//  LiveActivitiesSettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import Foundation
import Defaults

struct LiveActivitiesSettings: Equatable, Hashable, Codable, Defaults.Serializable {
    var enable = true
    var inactivityTimeoutInSecs: Double = 10
    var enabledLiveActivities: Set<NotchNook.LiveActivity> = [.shelf, .media]
    var interactiveActivities = true
}
