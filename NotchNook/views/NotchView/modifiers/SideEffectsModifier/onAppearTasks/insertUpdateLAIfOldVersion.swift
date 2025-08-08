//
//  insertUpdateLAIfOldVersion.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView.SideEffectsModifier {
    
    //TODO: we have to get the current remote version somehow and compare against the one currently being used, this is not being used the way it is
    func insertUpdateLAIfOldVersion() {
        if lastVersionNumber == "0" {
            liveActivitiesSettings.enabledLiveActivities.insert(.updateAvailable)
        }
    }

}
