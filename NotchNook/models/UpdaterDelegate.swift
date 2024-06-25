//
//  UpdaterDelegate.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import Foundation
import Sparkle

class UpdaterDelegate: NSObject, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool {
        return true
    }
    
    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
        LiveActivitiesManager.shared.activeLiveActivities.insert(.updateAvailable)
        return false
    }
}
