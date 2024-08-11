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
    var enabledLiveActivities: Set<LiveActivity> = [.tray, .media, .updateAvailable]
    var interactive = true
    var enableQuickPeek = true
    var enableHUDReplacement = false
    var disableColorsOnAudioHUDReplacement = false
    var unhideAutomatically = true
}
