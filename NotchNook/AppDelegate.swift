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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        _ = ShortcutsManager.shared
        _ = MediaPlayer.shared
//        MediaPlayer.shared.appleMusicApp?.updateTrack()
//        print(MediaPlayer.shared.appleMusicApp?.track)
        let screenF =  NSScreen.main?.frame ?? .zero
        let defaultNotchHeight = NSScreen.main?.safeAreaInsets.top ?? 0
        let view = NSHostingView(rootView: NotchView(defaultNotchHeight: defaultNotchHeight + 1))
        let size = view.intrinsicContentSize
        let newWindow = NSWindow(
            contentRect: .init(origin: .init(x: (screenF.width - size.width) / 2, y: screenF.height - size.height + 1), size: size),
//            contentRect: .init(origin: .init(x: (screenF.width - size.width) / 2, y: screenF.height - size.height - 200), size: size),
            styleMask: [.borderless],
            backing: .buffered, defer: true,
            screen: NSScreen.main
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
        
        windowController = newWindowController
    }
}
