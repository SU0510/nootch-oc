//
//  UpdaterDelegate.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import Foundation

#if !SETAPP_BUILD
import Sparkle

class UpdaterDelegate: NSObject, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool {
        return true
    }
    
    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
        ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.updateAvailable)
        return false
    }
}
#endif
