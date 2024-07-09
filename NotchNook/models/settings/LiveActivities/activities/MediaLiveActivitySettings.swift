//
//  MediaLiveActivitySettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import Foundation

struct MediaLiveActivitySettings: Preferences {
    var coloredSpectograph = true
    var albumCornerRadius: Double = 5
    var effect: MediaLiveActivityEffectEnum = .audioSpectrograph
    var gifOffset: Double = 0
}
