//
//  openCalendarAccountSettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/06/24.
//

import Foundation

import AppKit

func openCalendarAccountSettings() {
    let script = """
        tell application "Calendar"
            activate
            tell application "System Events"
                tell process "Calendar"
                    click menu item "Accounts…" of menu "Calendar" of menu bar 1
                end tell
            end tell
        end tell
        """
    
    var error: NSDictionary?
    if let scriptObject = NSAppleScript(source: script) {
        scriptObject.executeAndReturnError(&error)
    }
}
