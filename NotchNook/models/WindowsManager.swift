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
    static let shared = WindowsManager()
    
    var displayKits = [DisplayKit]()
    var settingsWindowController: SettingsWindowController?
    private var settingsPanes = [SettingsPane]()
    private var sparkleManager: SparkleManager
    private var changelogViewWindow: SwiftUIWindow<ChangelogView>?
    private var preventNextFocusFrontmostWindow = false
    private var expandedNoteManager = ExpandedNoteManager()
    private var expandedNoteWindowController: NSWindowController?
    private var updateWindowsWorkItem: DispatchWorkItem?
    private var lastKnownScreenConfigurations: [String: NSScreen.Configuration] = [:]
    
    private init() {
        print("WindowsManager: Initializing")
        self.sparkleManager = SparkleManager(updater: SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil).updater)
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(screenDidChange), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        updateLastKnownScreenConfigurations()
        updateWindows()
        
        expandedNoteManager.setOpenWindowFunction(openNoteWindow)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func debouncedUpdateWindows() {
        updateWindowsWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.updateWindows()
        }
        
        updateWindowsWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    private func updateWindows() {
        print("WindowsManager: Updating windows")
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
        print("WindowsManager: Windows updated, new display kit count: \(newDisplaysKits.count)")
    }
    
    func openNoteWindow(_ note: Note, inDisplayKitId: UUID) {
        print("WindowsManager: Opening note window for display kit ID: \(inDisplayKitId)")
        
        let screen = displayKits.first { $0.id == inDisplayKitId }?.windowController.window?.screen
        
        let newWindow = SwiftUIAnimatedWindow(styleMask: [.titled, .closable, .fullSizeContentView], screen: screen, origin: self.expandedNoteManager.windowOrigin ?? .zero) {
            ExpandedNoteView()
        }
        
        newWindow.whileClosing = {
            doAfter { self.expandedNoteManager.openNote(nil) }
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
        
        expandedNoteWindowController = windowController
        preventNextFocusFrontmostWindow = true
        NSApp.setActivationPolicy(.regular)
        
        if let windowOrigin = expandedNoteManager.windowOrigin {
            newWindow.show(origin: windowOrigin)
        }
        
        print("WindowsManager: Note window opened")
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
        guard NSScreen.main != nil else {
            return
        }
        
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
    
    private func setupDisplayKitForScreen(_ screen: NSScreen) -> DisplayKit {
        print("WindowsManager: Setting up display kit for screen: \(screen)")
        let displayKitId = UUID()
        let screenF = screen.frame
        let showSettings = settingsWindowController?.show ?? { _ in }
        let notchHeight = screen.safeAreaInsets.top
        let notchWidth = notchHeight == 0 ? 0 : NotchShape.notchWidthInInches * screen.pointsPerInch.width
        let notchSize = CGSize(width: notchWidth, height: notchHeight)
        let notchNook = NotchNookState()
        let hostingView = AcceptingFirstClickHostingView(
            rootView: RootView(
                displayKitId: displayKitId, 
                windowManager: self,
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

        hostingView.rootView.makeKeyWindow = {
            NSApp.activate()
            newWindow.makeKey()
        }
        
        hostingView.rootView.resignFirstResponder = {
            _ = newWindow.makeFirstResponder(nil)
        }
        
        newWindow.orderFrontRegardless()
        
        print("WindowsManager: Display kit setup complete for screen: \(screen)")
        return DisplayKit(
            id: displayKitId,
            windowController: newWindowController,
            screen: screen,
            notchSize: notchSize,
            notchNook: notchNook
        )
    }
    
    func getMostUpfrontWindowID() -> CGWindowID? {
        guard let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        
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
        if settingsWindowController?.window?.isVisible ?? false {
            return
        }
        
        guard let windowID = getMostUpfrontWindowID() else {
            return
        }
        let options = CGWindowListOption(arrayLiteral: .optionIncludingWindow, .excludeDesktopElements)
        let windowList = CGWindowListCopyWindowInfo(options, windowID) as? [[String: Any]]
        guard let windowInfo = windowList?.first,
              let pid = windowInfo[kCGWindowOwnerPID as String] as? pid_t else {
            return
        }
        
        let app = NSRunningApplication(processIdentifier: pid)
        app?.activate(options: [])
    }
    
    func enableTextEditingForWindow(with id: UUID) {
        if let displayKit = displayKits.first(where: { $0.id == id }),
           let window = displayKit.windowController.window as? ForceFocusableWindow {
            window.canThisWindowBecomeKeyWindow = true
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func updateEditingTextState(for displayKitId: UUID, isEditing: Bool) {
        if let displayKit = displayKits.first(where: { $0.id == displayKitId }),
           let window = displayKit.windowController.window as? ForceFocusableWindow {
            window.canThisWindowBecomeKeyWindow = isEditing
            if let hostingView = window.contentView as? AcceptingFirstClickHostingView<RootView> {
                hostingView.rootView.isEditingText = isEditing
            }
        }
    }
    
    @objc private func screenDidChange() {
        if hasSignificantScreenChanges() {
            debouncedUpdateWindows()
        }
    }
    
    private func hasSignificantScreenChanges() -> Bool {
        let currentScreens = NSScreen.screens
        
        // Check if the number of screens has changed
        if currentScreens.count != lastKnownScreenConfigurations.count {
            updateLastKnownScreenConfigurations()
            return true
        }
        
        // Check for significant changes in existing screens
        for screen in currentScreens {
            let screenID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            let screenIDString = screenID?.stringValue ?? UUID().uuidString
            
            guard let lastConfig = lastKnownScreenConfigurations[screenIDString] else {
                // New screen found
                updateLastKnownScreenConfigurations()
                return true
            }
            
            let currentConfig = screen.configuration
            
            // Check for changes in frame, scale factor, or color space
            if lastConfig.frame != currentConfig.frame ||
                lastConfig.backingScaleFactor != currentConfig.backingScaleFactor ||
                lastConfig.colorSpace.isEqual(currentConfig.colorSpace) == false {
                updateLastKnownScreenConfigurations()
                return true
            }
        }
        
        return false
    }
    
    private func updateLastKnownScreenConfigurations() {
        lastKnownScreenConfigurations = Dictionary(uniqueKeysWithValues: NSScreen.screens.map {
            let screenID = $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            let screenIDString = screenID?.stringValue ?? UUID().uuidString
            return (screenIDString, $0.configuration)
        })
    }
    
    struct DisplayKit {
        let id: UUID
        var windowController: NSWindowController
        var screen: NSScreen
        var notchSize: CGSize
        var notchNook: NotchNookState
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
    
    func enableTextEditing() {
        canThisWindowBecomeKeyWindow = true
        makeKeyAndOrderFront(nil)
    }
    
    override var canBecomeKey: Bool {
        canThisWindowBecomeKeyWindow
    }
    
    override func makeFirstResponder(_ responder: NSResponder?) -> Bool {
        let success = super.makeFirstResponder(responder)
        
        if success {
            firstResponderCb?(responder is NSWindow || responder == nil)
        }
        return success
    }
    
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

// Extension to capture relevant screen configuration
extension NSScreen {
    struct Configuration {
        let frame: CGRect
        let backingScaleFactor: CGFloat
        let colorSpace: NSColorSpace
    }
    
    var configuration: Configuration {
        return Configuration(frame: frame, backingScaleFactor: backingScaleFactor, colorSpace: colorSpace ?? .genericGray)
    }
}
