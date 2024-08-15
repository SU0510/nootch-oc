//
//  isTrialOver.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import Foundation
import Defaults
import SwiftDate

func isTrialOver(startTime: Double? = Defaults[.trialInitialTime]) -> Bool {
    if let startTime {
        let now = Date()
        return startTime > now.timeIntervalSince1970 || (((now.timeIntervalSince1970 - startTime) / 60) / 60) > LicenseManager.trialDurationInHours
    }
    return false
}
