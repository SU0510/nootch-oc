//
//  resetTrialAndHandleChangelog.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {
    func resetTrialAndHandleChangelog() {
        let currentBuildNumber = getBuildNumber()
        if lastBuildNumber != currentBuildNumber {
            resetTrial()
            if let lastBuildNumberInt = Int(lastBuildNumber), lastBuildNumberInt < 4 {
                showChangelog()
            }
            lastBuildNumber = currentBuildNumber
        }
    }
}
