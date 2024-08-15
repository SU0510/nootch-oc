//
//  AppDelegate.swift
//  NotchNook
//
//  Created by Igor Marcossi on 12/05/24.
//
import Foundation
import SwiftUI
#if !SETAPP_BUILD
import Sparkle
#endif
import AppKit
import SwiftDate
import SwiftData
import Defaults

@objc class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: NSWindowController? = nil
    var windowsManager: WindowsManager?
    var nsMenu: NSMenu?
#if !SETAPP_BUILD
    let updaterDelegate = UpdaterDelegate()
    let updaterController: SPUStandardUpdaterController
#endif
    
    override init() {
        SwiftDate.defaultRegion = Region.local
#if !SETAPP_BUILD
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: updaterDelegate, userDriverDelegate: updaterDelegate)
#endif
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        windowsManager?.settingsWindowController?.show()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize (in memory ig) all singletons
        CalendarManager.configureWithAppName("NotchNook")
        _ = ShortcutsManager.shared
        _ = MediaControls.shared
        _ = VolumeMonitor.shared
        _ = CurrentWallpaperManager.shared
        _ = LicenseManager.shared
        windowsManager = WindowsManager.shared
        
//        ValueTransformer.setValueTransformer(NSAttributedStringTransformer(), forName: .nsAttributedString)
        
        #if SETAPP_BUILD
        LicenseManager.shared.checkLicense()  // ensure that the license is considered registered
        #endif

        NSApp.setActivationPolicy(.accessory)
        setupMenu()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        HUDManager.enableSystemHUD()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        windowsManager?.settingsWindowController?.show()
        return true
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
