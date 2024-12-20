//
//  MediaLiveActivitySettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import Foundation

struct MediaLiveActivitySettings: Preferences {
    var isAutomaticallyColored = true
    var albumCornerRadius: Double = 5
    var effect: MediaLiveActivityEffectEnum = .audioSpectrograph
    var gifVerticalOffset: Double = 0
    var gifHorizontalOffset: Double = 0
    var customGifURL: URL? = nil
    var gifScale: Double = 1.0
    var gifScalingQuality: GIFScalingQuality = .pixelPerfect
    var selectedGIF: PredefinedGIF = .michael
}
