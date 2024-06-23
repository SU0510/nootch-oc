//
//  getShortVersion.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/06/24.
//

import Cocoa

func getShortVersion() -> String? {
    return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
}
