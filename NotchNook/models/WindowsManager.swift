//
//  WindowsManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/05/24.
//

import Foundation
import AppKit
import Settings
import SwiftUI
import Sparkle
import Observation

class WindowsManager {
    var displayKits = [DisplayKit]()
    var settingsWindowController: SettingsWindowController?
    private var settingsPanes = [SettingsPane]()
    private var sparkleManager: SparkleManager
    private var changelogViewWindow: SwiftUIWindow<ChangelogView>?
    private var preventNextFocusFrontmostWindow = false
    private var expandedNoteManager = ExpandedNoteManager()
    private var expandedNoteWindowController: NSWindowController?
    
    init(updater: SPUUpdater) {
        self.sparkleManager = SparkleManager(updater: updater)
        self.settingsPanes = [
            GeneralSettingsViewController(),
            GesturesSettingsViewController(),
            LiveActivitiesSettingsViewController(),
            NookSettingsViewController(),
            TraySettingsViewController(),
            DropAreaSettingsViewController(),
            LicenseSettingsViewController(),
            AboutSettingsViewController(sparkleManager, showChangelogViewWindow)
        ]
        
        settingsWindowController = SettingsWindowController(
            panes: self.settingsPanes,
            animated: true
        )
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateWindows), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateWindows), name: NSScreen.colorSpaceDidChangeNotification, object: nil)
        updateWindows()

        expandedNoteManager.openWindow = openNoteWindow
    }
    
    deinit {
        NotificationCenter.default.removeObserver(#selector(updateWindows), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NotificationCenter.default.removeObserver(#selector(updateWindows), name: NSScreen.colorSpaceDidChangeNotification, object: nil)
    }
    
    func openNoteWindow(_ note: Note) {
        
        let newWindow = SwiftUIAnimatedWindow(styleMask: [.titled, .closable, .fullSizeContentView]) {
            ExpandedNoteView()
        }
        
//        newWindow.onClose = {
//            doAfter { NSApp.setActivationPolicy(.accessory) }
//        }
        newWindow.whileClosing = {
            doAfter { self.expandedNoteManager.activeNote = nil }
        }
        
        let customToolbar = NSToolbar()
        customToolbar.showsBaselineSeparator = false
        newWindow.titlebarAppearsTransparent = true
        newWindow.titleVisibility = .hidden
        newWindow.toolbarStyle = .unified
        newWindow.styleMask.insert(.titled)
        newWindow.toolbar = customToolbar
        newWindow.isOpaque = false
        newWindow.backgroundColor = NSColor(Color.noteBG)
        
        let windowController = NSWindowController(window: newWindow)
        //        windowController.window?.contentView = viewHosting
        
        expandedNoteWindowController = windowController
        preventNextFocusFrontmostWindow = true
        NSApp.setActivationPolicy(.regular)
        newWindow.show()
    }
    
    func showChangelogViewWindow() {
        if let changelogViewWindow {
            if changelogViewWindow.isVisible {
                changelogViewWindow.show()
                return
            } else {
                self.changelogViewWindow = nil
            }
        }
        guard NSScreen.main != nil else { return }
        
        let newWindow = SwiftUIWindow(
            styleMask: [.titled, .closable, .fullSizeContentView],
            content: {
                ChangelogView()
            }, onClose: {
                self.changelogViewWindow = nil
            }
        )
        
        newWindow.isReleasedWhenClosed = false
        
        let customToolbar = NSToolbar()
        customToolbar.showsBaselineSeparator = false
        newWindow.titlebarAppearsTransparent = true
        newWindow.titleVisibility = .hidden
        newWindow.toolbarStyle = .unified
        newWindow.styleMask.insert(.titled)
        newWindow.toolbar = customToolbar
        newWindow.isOpaque = false
        
        newWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
        newWindow.standardWindowButton(.zoomButton)?.isHidden = true
        
        changelogViewWindow = newWindow
        
        newWindow.show()
    }
    
    @objc func updateWindows() {
        displayKits.forEach { kit in
            kit.windowController.close()
        }
        
        let screens = NSScreen.screens
        
        var newDisplaysKits = [DisplayKit]()
        screens.forEach { screen in
            let displayKit = self.setupDisplayKitForScreen(screen)
            newDisplaysKits.append(displayKit)
        }
        displayKits = newDisplaysKits
    }
    
    
    func setupDisplayKitForScreen(_ screen: NSScreen) -> DisplayKit {
        let id = UUID()
        let screenF = screen.frame
        let showSettings = settingsWindowController?.show ?? { _ in }
        let notchHeight = screen.safeAreaInsets.top
        let notchWidth = notchHeight == 0 ? 0 : NotchShape.notchWidthInInches * screen.pointsPerInch.width
        let notchSize = CGSize(width: notchWidth, height: notchHeight)
        let notchNook = NotchNook()
        let hostingView = AcceptingFirstClickHostingView(
            rootView: RootView(
                showSettings: showSettings,
                screenSize: screenF.size,
                sparkleManager: sparkleManager,
                showChangelog: showChangelogViewWindow,
                notchSize: notchSize,
                notchNook: notchNook,
                focusFrontmostWindow: focusFrontmostWindow,
                resignFirstResponder: {},
                preventNextFocusFrontmostWindow: { self.preventNextFocusFrontmostWindow = true },
                isEditingText: false,
                isKeyWindow: true,
                expandedNoteManager: expandedNoteManager
            )
        )
        let size = hostingView.intrinsicContentSize
        let newWindow = ForceFocusableWindow(
            contentRect: .init(
                origin: .init(
                    x: (screenF.width - size.width) / 2,
                    y: screenF.height - size.height + 1
                ),
                size: size),
            styleMask: [.borderless],
            backing: .buffered, defer: false,
            screen: screen
        )
        
        newWindow.firstResponderCb = { isTheWindow in
            hostingView.rootView.isEditingText = !isTheWindow
        }
        newWindow.becomeKeyCb = {
            hostingView.rootView.isKeyWindow = true
        }
        newWindow.resignedKeyCb = {
            hostingView.rootView.isKeyWindow = false
        }
        newWindow.firstResponderCb = { isTheWindow in
            hostingView.rootView.isEditingText = !isTheWindow
        }
        newWindow.isMovable = false
        newWindow.collectionBehavior = [
            .stationary, .canJoinAllSpaces, .canJoinAllApplications, .fullScreenAuxiliary, .ignoresCycle
        ]
        newWindow.backgroundColor = NSColor.clear
        newWindow.hasShadow = false
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.level = .mainMenu + 2
        newWindow.isOpaque = false
        
        newWindow.contentView = hostingView
        
        let newWindowController = NSWindowController(window: newWindow)
        
        hostingView.rootView.canBecomeKey = .init(get: {
            newWindow.canThisWindowBecomeKeyWindow
        }, set: { newWindow.canThisWindowBecomeKeyWindow = $0 })
        
        hostingView.rootView.makeKeyWindow = {
            NSApp.activate()
            newWindow.makeKey()
        }
        
        hostingView.rootView.resignFirstResponder = {
            _ = newWindow.makeFirstResponder(nil)
        }
        
        newWindow.orderFrontRegardless()
        
        return DisplayKit(
            id: id,
            windowController: newWindowController,
            screen: screen,
            notchSize: notchSize,
            notchNook: notchNook
        )
    }
    
    func getMostUpfrontWindowID() -> CGWindowID? {
        guard let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else { return nil }
        
        let windows = info.compactMap { window -> (CGWindowID, pid_t)? in
            guard let windowLayer = window[kCGWindowLayer as String] as? Int,
                  windowLayer == 0,
                  let windowOwnerPID = window[kCGWindowOwnerPID as String] as? pid_t,
                  let windowNumber = window[kCGWindowNumber as String] as? CGWindowID else { return nil }
            return (windowNumber, windowOwnerPID)
        }
        
        if let mostUpfrontWindow = windows.first {
            return mostUpfrontWindow.0
        }
        
        return nil
    }
    
    func focusFrontmostWindow() {
        if preventNextFocusFrontmostWindow {
            preventNextFocusFrontmostWindow = false
            return
        }
        // Prevent refocusing of previous app if settings screen is open
        if settingsWindowController?.window?.isVisible ?? false { return }
        
        guard let windowID = getMostUpfrontWindowID() else { return }
        let options = CGWindowListOption(arrayLiteral: .optionIncludingWindow, .excludeDesktopElements)
        let windowList = CGWindowListCopyWindowInfo(options, windowID) as? [[String: Any]]
        guard let windowInfo = windowList?.first,
              let pid = windowInfo[kCGWindowOwnerPID as String] as? pid_t else { return }
        
        let app = NSRunningApplication(processIdentifier: pid)
        app?.activate(options: [])
    }
    
    struct DisplayKit {
        let id: UUID
        var windowController: NSWindowController
        var screen: NSScreen
        var notchSize: CGSize
        var notchNook: NotchNook
    }
}

class ForceFocusableWindow: NSWindow, NSWindowDelegate {
    var becomeKeyCb: (() -> ())?
    var resignedKeyCb: (() -> ())?
    var firstResponderCb: ((_ isTheWindow: Bool) -> ())?
    var canThisWindowBecomeKeyWindow = false
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.delegate = self
    }
    
    override func makeFirstResponder(_ responder: NSResponder?) -> Bool {
        let success = super.makeFirstResponder(responder)
        
        if success {
            firstResponderCb?(responder is NSWindow || responder == nil)
        }
        return success
    }
    override var canBecomeKey: Bool { self.canThisWindowBecomeKeyWindow }
    
    func windowDidBecomeKey(_ notification: Notification) {
        becomeKeyCb?()
    }
    
    func windowDidResignKey(_ notification: Notification) {
        resignedKeyCb?()
    }
}

class AcceptingFirstClickHostingView<C: View>: NSHostingView<C> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

class MyWindow: NSWindow {
    
}
