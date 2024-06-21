//
//  AppDelegate.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import Foundation
import SwiftUI
import Sparkle
import AppKit
import SwiftDate

@objc class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: NSWindowController? = nil
    var windowsManager: WindowsManager?
    var nsMenu: NSMenu?
    let updaterDelegate = UpdaterDelegate()
    let updaterController: SPUStandardUpdaterController
    
    override init() {
        SwiftDate.defaultRegion = Region.local
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: updaterDelegate, userDriverDelegate: updaterDelegate)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize (in memory ig) all singletons
        CalendarManager.configureWithAppName("NotchNook")
        Task {
            _ = try? await CalendarManager.shared.fetchEventsForDaysOffset(CalendarWidgetView.showingDatesCount)
        }
        _ = ShortcutsManager.shared
        _ = MediaPlayer.shared
        _ = VolumeMonitor.shared
        _ = CurrentWallpaperManager.shared
        _ = LicenseManager.shared

        NSApp.setActivationPolicy(.accessory)
        setupMenu()
        windowsManager = WindowsManager(updater: updaterController.updater)
    }
    
    func setupMenu() {
        let mainMenu = NSMenu(title: "MainMenu")
        let menuItem = mainMenu.addItem(withTitle: "", action: nil, keyEquivalent: "")
        
        let submenu = NSMenu()
        submenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        submenu.addItem(withTitle: "Undo", action: #selector(EditMenuActions.undo(_:)), keyEquivalent: "z")
        submenu.addItem(withTitle: "Redo", action: #selector(EditMenuActions.redo(_:)), keyEquivalent: "Z")
        submenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        submenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        submenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        submenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        
        mainMenu.setSubmenu(submenu, for: menuItem)
        NSApp.mainMenu = mainMenu
    }
    
    @objc protocol EditMenuActions {
        func redo(_ sender: AnyObject)
        func undo(_ sender: AnyObject)
    }
}
