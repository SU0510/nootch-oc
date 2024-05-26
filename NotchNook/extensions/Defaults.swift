//
//  defaults.swift
//  NotchNook
//
//  Created by Ethan Bills on 5/23/24.
//

import SwiftUI
import Defaults

// Define the defaults keys
extension Defaults.Keys {
    static let email = Key<String>("email", default: "")
    static let licenseKey = Key<String>("licenseKey", default: "")
    static let keyActive = Key<Bool>("keyActive", default: false)
    
    static let inactiveLiveActivitiesTimeout = Key<Double>("inactiveLiveActivitiesTimeout", default: 10)
}
