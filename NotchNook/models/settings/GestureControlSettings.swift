//
//  GestureControlSettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import Foundation
import Defaults

struct GestureControlSettings: Equatable, Hashable, Codable, Defaults.Serializable {
    var allowGestures = true
    var controlMedia = true
    var controlOpenState = true
}
