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
            volumeAndBrightnessListener.addSideEffect(handleBriVolKeyPress, for: "default")
            if liveActivitiesSettings.enableHUDReplacement {
                volumeAndBrightnessListener.start()
            }
        }
    }
}
