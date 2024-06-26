//
//  checkTrialOver.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI
import SwiftDate

extension NotchView {
    func checkTrialOver() {
        if license == nil {
            if let trialInitialTime, (((Date().timeIntervalSince1970 - trialInitialTime) / 60) / 60) > LicenseManager.trialDurationInHours {
                if !trialOver { trialOver = true }
            } else {
                if trialOver { trialOver = false }
            }
        } else {
            if trialInitialTime != nil { trialInitialTime = nil }
            if trialOver { trialOver = false }
        }
    }
}
