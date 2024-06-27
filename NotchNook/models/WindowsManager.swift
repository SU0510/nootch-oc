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

class WindowsManager {
    var displayKits = [DisplayKit]()
    var settingsWindowController: SettingsWindowController?
    private var settingsPanes = [SettingsPane]()
    private var sparkleManager: SparkleManager
    private var changelogViewWindow: SwiftUIWindow<ChangelogView>?
    private var previouslyFocusedWindow: CGWindowID?
    
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
    }
    
    deinit {
        NotificationCenter.default.removeObserver(#selector(updateWindows), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NotificationCenter.default.removeObserver(#selector(updateWindows), name: NSScreen.colorSpaceDidChangeNotification, object: nil)
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
                captureFocusedWindow: captureFocusedWindow,
                refocusStoredWindow: refocusStoredWindow
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
        
        newWindow.orderFrontRegardless()
        
        return DisplayKit(
            id: id,
            windowController: newWindowController,
            screen: screen,
            notchSize: notchSize,
            notchNook: notchNook
        )
    }
    
    func getFocusedWindowID(filterItselfOut: Bool = true) -> CGWindowID? {
        let currentPID = NSRunningApplication.current.processIdentifier
        guard let info = CGWindowListCopyWindowInfo([.excludeDesktopElements, .optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else { return nil }

        var windows = info.compactMap { window -> (CGWindowID, pid_t)? in
            guard let windowLayer = window[kCGWindowLayer as String] as? Int, windowLayer == 0,
                  let windowOwnerPID = window[kCGWindowOwnerPID as String] as? pid_t,
                  let windowNumber = window[kCGWindowNumber as String] as? CGWindowID else { return nil }
            return (windowNumber, windowOwnerPID)
        }.sorted { $0.0 < $1.0 }
        
        if windows.count > 0 {
            return windows[0].0
        }

//        let focusedIndex = windows.firstIndex(where: { NSRunningApplication(processIdentifier: $0.1)?.isActive == true })
//        if let index = focusedIndex, index + 1 < windows.count {
//            return windows[index + 1].0
//        }

        return nil
    }
    
    func captureFocusedWindow() {
        if let focusedWindowID = getFocusedWindowID() {
            previouslyFocusedWindow = focusedWindowID
        }
    }
    
    func refocusStoredWindow() {
        // Prevent refocusing of previous app if settings screen is open
        if settingsWindowController?.window?.isVisible ?? false { return }
        
        guard let windowID = previouslyFocusedWindow else { return }
        let options = CGWindowListOption(arrayLiteral: .optionIncludingWindow, .excludeDesktopElements)
        let windowList = CGWindowListCopyWindowInfo(options, windowID) as? [[String: Any]]
        guard let windowInfo = windowList?.first,
              let pid = windowInfo[kCGWindowOwnerPID as String] as? pid_t else { return }
        
        let app = NSRunningApplication(processIdentifier: pid)
        app?.activate(options: [])
        previouslyFocusedWindow = nil
    }
    
    struct DisplayKit {
        let id: UUID
        var windowController: NSWindowController
        var screen: NSScreen
        var notchSize: CGSize
        var notchNook: NotchNook
    }
}

class ForceFocusableWindow: NSWindow {
    var canThisWindowBecomeKeyWindow = false
    override var canBecomeKey: Bool { self.canThisWindowBecomeKeyWindow }
}

class AcceptingFirstClickHostingView<C: View>: NSHostingView<C> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
