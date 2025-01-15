//
//  PowerInfoStruct.swift
//  NotchNook
//
//  Created by Hasan Sultan on 8/13/24.
//

import Foundation

struct ACPower: Codable, Hashable {
    var name: String?
    var timeLeftTo100: Int?
    var currentStateOfCharge: Int?
}

struct BatteryPower: Codable, Hashable {
    var name: String?
    var currentStateOfCharge: Int?
    var isCharging: Bool?
    var timeToEmpty: Int?
}

struct PowerInfoStruct: Codable, Hashable {
    var ACPower: ACPower? = nil
    var BatteryPower: BatteryPower? = nil
}
