//
//  LiveActivitiesManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/06/24.
//

import SwiftUI
import Defaults

@Observable
class LiveActivitiesManager {
    static let shared = LiveActivitiesManager()
    var activeLiveActivities: Set<LiveActivity> {
        get { Defaults[.liveActivitiesSettings].enabled ? _activeLiveActivities : [] }
        set { withAnimation(TopBarView.animation) { _activeLiveActivities = newValue } }
    }
    private var _activeLiveActivities = Set<LiveActivity>()
}
