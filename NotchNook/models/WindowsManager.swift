//
//  WindowsManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/05/24.
//

import Foundation
import AppKit
import SwiftUI

class WindowsManager {
    var displayKits = [DisplayKit]()
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateWindows), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateWindows), name: NSScreen.colorSpaceDidChangeNotification, object: nil)
        updateWindows()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(#selector(updateWindows), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NotificationCenter.default.removeObserver(#selector(updateWindows), name: NSScreen.colorSpaceDidChangeNotification, object: nil)
    }
    
    @objc func updateWindows() {
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
        var notchHeight = screen.safeAreaInsets.top
        notchHeight = notchHeight.isZero ? NotchShape.notchlessScreenNotchHeight : notchHeight
        let screenF = screen.frame
        let view = NSHostingView(rootView: NotchView(screenID: id, defaultNotchHeight: notchHeight + 1))
        let size = view.intrinsicContentSize
        let newWindow = NSWindow(
            contentRect: .init(
                origin: .init(
                    x: (screenF.width - size.width) / 2,
                    y: screenF.height - size.height + 1
                ),
                size: size),
            styleMask: [.borderless],
            backing: .buffered, defer: true,
            screen: screen
        )
        NSApp.setActivationPolicy(.accessory)
        
        newWindow.collectionBehavior = [.stationary, .canJoinAllSpaces, .fullScreenNone]
        newWindow.backgroundColor = NSColor.clear
        newWindow.hasShadow = false
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.level = .mainMenu + 2
        newWindow.orderFront(0)
        newWindow.contentView = view
        newWindow.isOpaque = false
        
        let newWindowController = NSWindowController(window: newWindow)
        
        return DisplayKit(id: id, windowController: newWindowController, screen: screen, notchHeight: notchHeight)
    }
    
    struct DisplayKit {
        let id: UUID
        var windowController: NSWindowController
        var screen: NSScreen
        var notchHeight: Double
    }
}
