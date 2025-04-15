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
        
        if shouldShowChangelog(lastBuildNumber: lastBuildNumber, currentBuildNumber: currentBuildNumber) {
#if !SETAPP_BUILD
            resetTrial()
#endif
            showChangelog()
            lastBuildNumber = currentBuildNumber
        }
    }
    
    /// Compare major and minor version components
    func shouldShowChangelog(lastBuildNumber: String, currentBuildNumber: String) -> Bool {
        let lastComponents = lastBuildNumber.split(separator: ".")
        let currentComponents = currentBuildNumber.split(separator: ".")
        
        guard lastComponents.count >= 2 && currentComponents.count >= 2 else {
            return lastBuildNumber != currentBuildNumber
        }
        
        if lastComponents[1] != currentComponents[1] { return true }
        if lastComponents[0] != currentComponents[0] { return true }
        return false
    }
}
