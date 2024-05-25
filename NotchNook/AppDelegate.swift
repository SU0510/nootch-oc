//
//  AppDelegate.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import Foundation
import SwiftUI
import AppKit

@objc class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: NSWindowController? = nil
    var windowsManager = WindowsManager()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        _ = ShortcutsManager.shared
        _ = MediaPlayer.shared

        NSApp.setActivationPolicy(.accessory)
    }
}
