//
//  isTrialOver.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import Foundation
import Defaults

func isTrialOver(startTime: Double? = Defaults[.trialInitialTime]) -> Bool {
    if let startTime {
        return (((Date().timeIntervalSince1970 - startTime) / 60) / 60) > LicenseManager.trialDurationInHours
    }
    return false
}
