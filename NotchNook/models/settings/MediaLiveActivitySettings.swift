//
//  MediaLiveActivitySettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import Foundation
import Defaults

struct MediaLiveActivitySettings: Equatable, Hashable, Codable, Defaults.Serializable {
    var coloredSpectograph = true
    var albumCornerRadius: Double = 5
}
