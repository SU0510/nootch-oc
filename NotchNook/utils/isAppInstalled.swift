//
//  isAppInstalled.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//

import Foundation
import AppKit

func isAppInstalled(_ bundleID: String) -> Bool {
    let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    return appURL != nil
}
