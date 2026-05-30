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
        
        // Bug 2: ensure NSApp.setActivationPolicy(.accessory) is always reset when the
        // expanded-note window is closed, regardless of whether the SwiftUI NoteView
        // is alive to observe expandedNoteManager.isExpanded flipping.  whileClosing fires
        // at the START of the close animation (before super.close()); onClose fires after.
        //
        // Use a weak capture of `self` (WindowsManager is a singleton but keeping it weak
        // is correct hygiene), and a weak capture of `newWindow` to avoid a retain cycle
        // (window → WindowsManager via the closure → window).
        newWindow.whileClosing = { [weak self] in
            self?.expandedNoteManager.closeNote()
            // Clear the controller reference immediately so the window can be released
            // when the animation completes.
            self?.expandedNoteWindowController = nil
        }
        // Reset activation policy after the close animation finishes and super.close() runs.
        // This ensures the Dock + Cmd-Tab leak is fixed even when NoteView's SwiftUI
        // onChange handler never fires (e.g. red-X close while notch is fully closed).
        newWindow.onClose = {
            NSApp.setActivationPolicy(.accessory)
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
        // NSPanel: .nonactivatingPanel already prevents stealing the owning app's activation,
        // so we allow the panel to become key on any click. This activates cursor tracking areas
        // (I-beam over text inputs) and ensures first-click focus works on RichTextKit's NSTextView.
        newWindow.becomesKeyOnlyIfNeeded = false
        newWindow.worksWhenModal = true

        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true

        newWindow.contentView = hostingView

        let newWindowController = NSWindowController(window: newWindow)

        hostingView.rootView.resignFirstResponder = {
            _ = newWindow.makeFirstResponder(nil)
        }

        // isEditingText universal tracker: true only when a text editor is the active
        // first responder — the field editor (NSTextView) when an NSTextField/SwiftUI
        // TextField is focused, or an NSText subclass for TextEditor. AppKit sets the
        // initial responder to the contentView (NSHostingView) on panel open, so a
        // "non-self" check would spuriously light up the kb-lock indicator before the
        // user types anything. Explicit setters in NoteView/TrayFileView still run.
        newWindow.firstResponderCb = { [weak hostingView, weak newWindow] responder in
            if (responder is NSText) || (responder is NSTextField) {
                // Field editor (NSTextView) or a native NSTextField is active — text is being edited.
                hostingView?.rootView.isEditingText = true
            } else if responder == nil || responder === newWindow {
                // Explicit "no editor" signal: panel lost focus entirely, or AppKit resigned the
                // panel itself.  Clear the flag so unhover-close can arm again.
                hostingView?.rootView.isEditingText = false
            }
            // All other responder types (NSView, NSHostingView, NSButton, …) are transient
            // mid-transition intermediates.  Leave the flag alone — the explicit close paths
            // in NoteView (updateEditingTextStateFor) and the NSText match above handle real
            // transitions without spuriously disarming the text-lock.
        }

        // Bug 3: re-arm auto-close when another window (e.g. Settings) steals key status.
        // The old `onChange(of: isKeyWindow)` approach was removed in a60216d because
        // .nonactivatingPanel normally never becomes key on its own.  But it *does* resign
        // key when a regular NSWindow opens.  Observe that notification here so we can
        // close the notch without needing a SwiftUI env accessor.
        //
        // Guard: skip the close when a text field is active — the user is typing in the
        // notch, and the panel will resign key to the field editor's parent; closing then
        // would interrupt editing.
        //
        // The block-based addObserver API returns an opaque token that must be stored and
        // passed to removeObserver(_:) explicitly — removeObserver(window) only removes
        // selector-based registrations, not block-based ones.  Store the token in DisplayKit.
        let resignKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: newWindow,
            queue: .main
        ) { [weak hostingView] _ in
            guard hostingView?.rootView.isEditingText == false else { return }
            withAnimation(.smooth(duration: 0.4)) {
                hostingView?.rootView.notchNook.mode = .closed
            }
        }

        newWindow.orderFrontRegardless()
        
        return DisplayKit(
            id: displayKitId,
            windowController: newWindowController,
            screen: screen,
            notchSize: notchSize,
            notchNook: notchNook,
            resignKeyObserver: resignKeyObserver
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
        /// Token for the block-based didResignKeyNotification observer (Bug 3).
        /// Must be removed explicitly; removeObserver(window) only handles selector-based
        /// registrations and will NOT remove block-based observers.
        var resignKeyObserver: NSObjectProtocol?
        
        func cleanup() {
            if let window = windowController.window {
                // Remove selector-based observers registered with `object: window` as the sender.
                NotificationCenter.default.removeObserver(window)
                
                if let hostingView = window.contentView as? AcceptingFirstClickHostingView<RootView> {
                    hostingView.rootView.resignFirstResponder = {}
                }
                window.contentView = nil
            }
            
            // Remove the block-based resign-key observer stored at construction time.
            if let resignKeyObserver {
                NotificationCenter.default.removeObserver(resignKeyObserver)
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
