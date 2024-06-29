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
                if !state.trialOver { state.trialOver = true }
            } else {
                if state.trialOver { state.trialOver = false }
            }
        } else {
            if trialInitialTime != nil { trialInitialTime = nil }
            if state.trialOver { state.trialOver = false }
        }
    }
}

extension NotchView.EnvironmentsModifier {
    func checkTrialOver() {
        if license == nil {
            if let trialInitialTime, (((Date().timeIntervalSince1970 - trialInitialTime) / 60) / 60) > LicenseManager.trialDurationInHours {
                if !state.trialOver { state.trialOver = true }
            } else {
                if state.trialOver { state.trialOver = false }
            }
        } else {
            if trialInitialTime != nil { trialInitialTime = nil }
            if state.trialOver { state.trialOver = false }
        }
    }
}
