//
//  BatteryLiveActivitySettings.swift
//  NotchNook
//
//  Created by Hasan Sultan on 8/19/24.
//

import Foundation

struct BatteryLiveActivitySettings: Preferences {
    var lowBatteryThreshold: Int = 20
    var showWhenPluggedIn: Bool = true
    var showWhenUnplugged: Bool = true
    var showWhenFullyCharged: Bool = true
    var showLowBatteryWarning: Bool = true
}
