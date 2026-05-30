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
#if !SETAPP_BUILD
import Sparkle
#endif
import Observation

class WindowsManager {
    
    static let shared = WindowsManager()

    var displayKits = [DisplayKit]()
    var settingsWindowController: SettingsWindowController?
    private var settingsPanes = [SettingsPane]()
#if !SETAPP_BUILD
    private var sparkleManager: SparkleManager
#endif
    private var changelogViewWindow: SwiftUIWindow<ChangelogView>?
    private var expandedNoteManager = ExpandedNoteManager()
    private var expandedNoteWindowController: NSWindowController?
    private var updateWindowsWorkItem: DispatchWorkItem?
    private var lastKnownScreenConfigurations: [String: NSScreen.Configuration] = [:]
    
    private init() {
#if !SETAPP_BUILD
        self.sparkleManager = SparkleManager(updaterController: SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil))
#endif
        
        var newSettingsPanes: [SettingsPane] = [
            GeneralSettingsViewController(),
            GesturesSettingsViewController(),
            LiveActivitiesSettingsViewController(),
            NookSettingsViewController(),
            TraySettingsViewController(),
            DropAreaSettingsViewController(),
            LicenseSettingsViewController(),
        ]
        
#if !SETAPP_BUILD
        newSettingsPanes.append(AboutSettingsViewController(sparkleManager, showChangelogViewWindow))
#else
        AboutSettingsViewController(showChangelogViewWindow)
#endif
        
        self.settingsPanes = newSettingsPanes
        
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
    
    private func debouncedUpdateWindows() {
        updateWindowsWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.updateWindows()
        }
        
        updateWindowsWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }
    
    private func updateWindows() {
        // Properly cleanup old display kits
        displayKits.forEach { kit in
            kit.cleanup()
        }
        displayKits.removeAll()
        
        autoreleasepool {
            let newDisplaysKits = NSScreen.screens.map { screen in
                setupDisplayKitForScreen(screen)
            }
            displayKits = newDisplaysKits
        }
        
        displayKits.forEach { $0.windowController.window?.orderFrontRegardless() }
    }
    
    func openNoteWindow(_ note: Note, inDisplayKitId: UUID, isCodeMode: Bool) {
        let screen = displayKits.first { $0.id == inDisplayKitId }?.windowController.window?.screen
        
        let newWindow = SwiftUIAnimatedWindow(styleMask: [.titled, .closable, .fullSizeContentView], screen: screen, origin: self.expandedNoteManager.windowOrigin ?? .zero) {
            ExpandedNoteView(note: note, isCodeMode: isCodeMode)
        }
        
        newWindow.whileClosing = {
            doAfter { self.expandedNoteManager.closeNote() }
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
        NSApp.setActivationPolicy(.regular)
        
        if let windowOrigin = expandedNoteManager.windowOrigin {
            newWindow.show(origin: windowOrigin)
        }
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
    
    private func setupDisplayKitForScreen(_ screen: NSScreen) -> DisplayKit {
        let displayKitId = UUID()
        let screenFrame = screen.frame
        let showSettings = settingsWindowController?.show ?? { _ in }
        let notchHeight = screen.safeAreaInsets.top
        let notchWidth = notchHeight == 0 ? 0 : NotchShape.notchWidthInInches * screen.pointsPerInch.width
        let notchSize = CGSize(width: notchWidth, height: notchHeight)
        let notchNook = NotchNookState()
        
        
        // Closures capture hostingView — forward-declared here, assigned after creation.
        var enableTextEditing: (_ id: UUID) -> () = { _ in }
        var updateEditingTextState: (_ id: UUID, _ isEditing: Bool) -> () = { _, _ in }

#if !SETAPP_BUILD
        let hostingView = AcceptingFirstClickHostingView(
            rootView: RootView(
                displayKitId: displayKitId,
                enableTextEditingForWindowWith: { id in enableTextEditing(id) },
                updateEditingTextStateFor: { id, editing in updateEditingTextState(id, editing) },
                showSettings: showSettings,
                screenSize: screenFrame.size,
                screen: screen,
                sparkleManager: sparkleManager,
                showChangelog: showChangelogViewWindow,
                notchSize: notchSize,
                notchNook: notchNook,
                resignFirstResponder: {},
                isEditingText: false,
                isKeyWindow: true,
                expandedNoteManager: expandedNoteManager,
                showIndicator: { [weak self] indicator, onAllScreens in self?.showIndicator(indicator, onAllScreens) }
            )
        )
#else
        let hostingView = AcceptingFirstClickHostingView(
            rootView: RootView(
                displayKitId: displayKitId,
                enableTextEditingForWindowWith: { id in enableTextEditing(id) },
                updateEditingTextStateFor: { id, editing in updateEditingTextState(id, editing) },
                showSettings: showSettings,
                screenSize: screenFrame.size,
                screen: screen,
                showChangelog: showChangelogViewWindow,
                notchSize: notchSize,
                notchNook: notchNook,
                resignFirstResponder: {},
                isEditingText: false,
                isKeyWindow: true,
                expandedNoteManager: expandedNoteManager,
                showIndicator: { [weak self] indicator, onAllScreens in self?.showIndicator(indicator, onAllScreens) }
            )
        )
#endif

        // Wire up isEditingText tracking now that hostingView exists.
        // NSPanel handles focus natively; these closures only update the SwiftUI state.
        enableTextEditing = { [weak hostingView] _ in
            hostingView?.rootView.isEditingText = true
        }
        updateEditingTextState = { [weak hostingView] _, isEditing in
            hostingView?.rootView.isEditingText = isEditing
        }
        
        
        let size = hostingView.intrinsicContentSize
        let newWindow = ForceFocusableWindow(
            contentRect: .init(
                origin: .init(
                    x: (screenFrame.width - size.width) / 2,
                    y: screenFrame.height - size.height + 1
                ),
                size: size),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered, defer: false,
            screen: screen
        )
        newWindow.level = .statusBar
        newWindow.collectionBehavior = [
            .stationary, .canJoinAllSpaces, .canJoinAllApplications, .fullScreenAuxiliary, .ignoresCycle
        ]
        newWindow.isOpaque = false
        newWindow.backgroundColor = NSColor.clear
        newWindow.hasShadow = false
        newWindow.isMovable = false
        newWindow.isReleasedWhenClosed = false
        newWindow.hidesOnDeactivate = false
        // NSPanel: become key only when a field needs it; never steals app focus otherwise.
        newWindow.becomesKeyOnlyIfNeeded = true
        newWindow.worksWhenModal = true

        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true

        newWindow.contentView = hostingView

        let newWindowController = NSWindowController(window: newWindow)

        hostingView.rootView.resignFirstResponder = {
            _ = newWindow.makeFirstResponder(nil)
        }
        
        newWindow.orderFrontRegardless()
        
        return DisplayKit(
            id: displayKitId,
            windowController: newWindowController,
            screen: screen,
            notchSize: notchSize,
            notchNook: notchNook
        )
    }
    
    private func showIndicator(_ indicator: Indicator?, _ onAllScreens: Bool) {
        if onAllScreens {
            displayKits.forEach { kit in
                guard let hostingView = kit.windowController.window?.contentView as? AcceptingFirstClickHostingView<RootView> else { return }
                hostingView.rootView.notchNook.indicator = indicator
            }
        } else {
            guard let mainDisplayKit = displayKits.first(where: { $0.screen == NSScreen.main }) else { return }
            guard let hostingView = mainDisplayKit.windowController.window?.contentView as? AcceptingFirstClickHostingView<RootView> else { return }
            hostingView.rootView.notchNook.indicator = indicator
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
        
        func cleanup() {
            if let window = windowController.window {
                NotificationCenter.default.removeObserver(window)
                
                if let hostingView = window.contentView as? AcceptingFirstClickHostingView<RootView> {
                    hostingView.rootView.resignFirstResponder = {}
                }
                window.contentView = nil
            }
            
            windowController.close()
            
            notchNook.cleanup()
        }
    }
}

class AcceptingFirstClickHostingView<C: View>: NSHostingView<C> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
