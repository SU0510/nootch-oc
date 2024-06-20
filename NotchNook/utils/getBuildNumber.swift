//
//  getBuildNumber.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import Foundation

func getBuildNumber() -> String {
    return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
}
