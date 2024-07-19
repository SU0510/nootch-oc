//
//  SystemIntegrationHelper.swift
//  DockDoor
//
//  Created by Ethan Bills on 6/3/24.
//

import AppKit

class SystemIntegrationHelper {
    static func openAccessibilityPreferences() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    
    static func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
