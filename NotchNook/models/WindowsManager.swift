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
    
    init(updater: SPUUpdater) {
        self.sparkleManager = SparkleManager(updater: updater)
        self.settingsPanes = [
            GeneralSettingsViewController(),
            GesturesSettingsViewController(),
            LiveActivitiesSettingsViewController(),
            NookSettingsViewController(),
            ShelfSettingsViewController(),
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
        guard let screen = NSScreen.main else { return }
        let screenF = screen.frame
        
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
        let view = NSHostingView(
            rootView:
                NotchView()
                .environment(\.openSettings, showSettings)
                .environment(\.screenID, id)
                .environment(\.screenSize, screenF.size)
                .environment(\.sparkleManager, sparkleManager)
                .environment(\.showChangelog, showChangelogViewWindow)
                .environment(\.notchSize, notchSize)
        )
        let size = view.intrinsicContentSize
        let newWindow = NSWindow(
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
        newWindow.orderFront(0)
        newWindow.contentView = view
        newWindow.isOpaque = false
        
        let newWindowController = NSWindowController(window: newWindow)
        
        return DisplayKit(id: id, windowController: newWindowController, screen: screen, notchSize: notchSize)
    }
    
    struct DisplayKit {
        let id: UUID
        var windowController: NSWindowController
        var screen: NSScreen
        var notchSize: CGSize
    }
}
