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
                // .timerExpired is always-on — it surfaces regardless of the user toggle list
                $0 == .timerExpired || liveActivitiesSettingsCache.enabledLiveActivities.contains($0)
            }
            return isCacheEnabled ? liveActivitiesFromCache : _activeLiveActivities.filter { $0 == .timerExpired }
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

    // MARK: - Synchronous main-thread mutations
    // Use these from @MainActor call sites to avoid the async Task hop in the
    // computed-property setter — the hop defers the write to the next run-loop
    // cycle, which means the view reads an empty set during the first layout pass
    // after insertion (notch grows but content is blank).

    @MainActor func insertSync(_ activity: LiveActivity) {
        withAnimation(TopBarView.animation) { _activeLiveActivities.insert(activity) }
    }

    @MainActor func removeSync(_ activity: LiveActivity) {
        withAnimation(TopBarView.animation) { _activeLiveActivities.remove(activity) }
    }
}
