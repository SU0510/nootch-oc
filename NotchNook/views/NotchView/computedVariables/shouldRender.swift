//
//  shouldRender.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/06/24.
//

import Foundation

extension NotchView {
    var shouldRender: Bool {
        let showingLiveActvs = LiveActivitiesManager.shared.activeLiveActivities.filter {
            liveActivitiesSettings.enabledLiveActivities.contains($0)
        }
        return (
            notchNook.mode != .closed ||
            fineTuningNotchWidth ||
            (intro && showIntro) ||
            !showingLiveActvs.isEmpty ||
            generalSettings.demoMode ||
            notchSize.height == 0 ||
            hovering ||
            animatingBack
        )
    }
}
