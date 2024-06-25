//
//  insertUpdateLAIfOldVersion.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {
    func insertUpdateLAIfOldVersion() {
        if lastBuildNumber == "0" { liveActivitiesSettings.enabledLiveActivities.insert(.updateAvailable) }
    }
}
