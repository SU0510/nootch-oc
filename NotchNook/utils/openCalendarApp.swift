//
//  openCalendarApp.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/06/24.
//

import Foundation

import AppKit

func openCalendarApp() {
    NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/Calendar.app"), configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
}
