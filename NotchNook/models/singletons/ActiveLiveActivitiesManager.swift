//
//  ActiveLiveActivitiesManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/06/24.
//

import SwiftUI
import Defaults

@Observable
class ActiveLiveActivitiesManager {
    static let shared = ActiveLiveActivitiesManager()
    var activeLiveActivities: Set<LiveActivity> {
        get { liveActivitiesSettingsCache.enabled ? _activeLiveActivities.filter { liveActivitiesSettingsCache.enabledLiveActivities.contains($0) } : [] }
        set { withAnimation(TopBarView.animation) { _activeLiveActivities = newValue } }
    }
    private var _activeLiveActivities = Set<LiveActivity>()
    private var liveActivitiesSettingsCache: LiveActivitiesSettings = Defaults[.liveActivitiesSettings]
    private var task: Task<Void, Never>?
    
    private init() {
        task = Task {
            for await value in Defaults.updates(.liveActivitiesSettings) {
                self.liveActivitiesSettingsCache = value
            }
        }
    }
    
    deinit {
        task?.cancel()
    }
}
