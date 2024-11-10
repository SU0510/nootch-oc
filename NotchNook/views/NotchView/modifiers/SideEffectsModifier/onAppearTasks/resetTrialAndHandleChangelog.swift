//
//  resetTrialAndHandleChangelog.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView.SideEffectsModifier {
    func resetTrialAndHandleChangelog() {
        let currentBuildNumber = getBuildNumber()
        if lastBuildNumber != currentBuildNumber {
#if !SETAPP_BUILD
            resetTrial()
#endif
            showChangelog()
            lastBuildNumber = currentBuildNumber
        }
    }
}
