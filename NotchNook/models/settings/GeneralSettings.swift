//
//  GeneralSettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import Foundation

struct GeneralSettings: Preferences {
    var alwaysOpenNotchOnHover = false
    var transluscent = false
    var handleSize = CGSize(width: 184, height: 8)
    var contentPadding: Double = 16
    var transparentHandle = false
    var disableHaptics = false
    var enableOnNonNotchScreens = true
}
