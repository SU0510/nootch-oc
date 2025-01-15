//
//  BatteryLiveActivitySettings.swift
//  NotchNook
//
//  Created by Hasan Sultan on 8/19/24.
//

import Foundation

struct BatteryLiveActivitySettings: Preferences {
    var notifyOnChargePercentage: UInt = 5
    var notifyTimeLeftOnBattery: UInt = 30
}
