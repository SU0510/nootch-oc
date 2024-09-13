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
        get {
            let isCacheEnabled = liveActivitiesSettingsCache.enabled
            let liveActivitiesFromCache = _activeLiveActivities.filter {
                liveActivitiesSettingsCache.enabledLiveActivities.contains($0)
            }
            return isCacheEnabled ? liveActivitiesFromCache : []
        }
        set {
            Task { @MainActor in
                withAnimation(TopBarView.animation) { _activeLiveActivities = newValue }
            }
        }
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
