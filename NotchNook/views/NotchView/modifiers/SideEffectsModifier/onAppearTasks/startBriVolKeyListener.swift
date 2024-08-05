//
//  startBriVolKeyListener.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/07/24.
//

import SwiftUI

extension NotchView.SideEffectsModifier {
    func startBriVolKeyListener() {
        if notchSize.height != 0 {
            if liveActivitiesSettings.enableHUDReplacement {
                VolumeAndBrightnessListener.shared.start()
                VolumeAndBrightnessListener.shared.addSideEffect(handleBriVolKeyPress, for: "default")
            }
        }
    }
}
