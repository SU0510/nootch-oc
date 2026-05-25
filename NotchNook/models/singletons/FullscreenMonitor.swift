//
//  FullscreenMonitor.swift
//  NotchNook
//
//  Created by Lori Montenegro on 23/10/24.
//

import SwiftUI
import ApplicationServices

@Observable
class FullscreenMonitor: NSObject {
    
    static let shared = FullscreenMonitor()
    
    var fullScreenStateDict: [NSScreen: Bool] = [:]
    
    private let workspaceNotificationCenter = NSWorkspace.shared.notificationCenter
    
    override init() {
        super.init()
        setupObservers()
        updateAccessibilityStatus()
    }
    
    private func updateAccessibilityStatus() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let isAccessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if isAccessibilityEnabled {
            fullScreenStateDict = getFullscreenStates()
        } else {
            fullScreenStateDict = [:]
        }
    }

    private func setupObservers() {
        workspaceNotificationCenter.addObserver(self, selector: #selector(somethingChanged), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        workspaceNotificationCenter.addObserver(self, selector: #selector(somethingChanged), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(somethingChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(somethingChanged), name: NSNotification.Name("com.apple.accessibility.api"), object: nil)
    }
    
    @objc private func somethingChanged() {
        DispatchQueue.main.async {
            self.updateAccessibilityStatus()
        }
    }
    
    func getFullscreenStates() -> [NSScreen: Bool] {
        guard AXIsProcessTrusted() else { return [:] }
        
        var fullscreenStates: [NSScreen: Bool] = [:]
        
        for screen in NSScreen.screens {
            let isFullscreen = isFullScreenForScreen(screen)
            
            fullscreenStates[screen] = isFullscreen
        }
        
        return fullscreenStates
    }
    
    private func isFullScreenForScreen(_ screen: NSScreen) -> Bool {
        guard AXIsProcessTrusted() else { return false }

        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            guard app.activationPolicy == .regular else { continue }
            
            let appRef = AXUIElementCreateApplication(app.processIdentifier)
            var windowList: CFTypeRef?
            
            let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowList)
            
            guard result == .success,
                  let windows = windowList as? [AXUIElement] else { continue }
            
            for window in windows {
                guard let positionAndSize = getPositionAndSizeRefs(window: window) else { continue }
                
                let windowFrame = CGRect(origin: positionAndSize.position, size: positionAndSize.size)
                
                // Convert window frame to screen coordinates
                let convertedWindowFrame = convertWindowFrameToScreenCoordinates(windowFrame, for: screen)
                                
                // Check if window is inside this screen
                guard convertedWindowFrame.size.height > 100 && screen.frame.intersects(convertedWindowFrame) else { continue }
                
                // Check for fullscreen flag
                var fullScreenRef: AnyObject?
                AXUIElementCopyAttributeValue(window, "AXFullScreen" as CFString, &fullScreenRef)
                let isFullScreen = (fullScreenRef as? Bool) ?? false
                if isFullScreen { return true }
            }
        }
        
        return false
    }
    
    private func getPositionAndSizeRefs(window: AXUIElement) -> (position: CGPoint, size: CGSize)? {
        var positionRef: AnyObject?
        var sizeRef: AnyObject?
        
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        
        guard let positionValue = positionRef as! AXValue?,
              let sizeValue = sizeRef as! AXValue? else {
            return nil
        }
        
        var position = CGPoint.zero
        var size = CGSize.zero
        
        AXValueGetValue(positionValue, .cgPoint, &position)
        AXValueGetValue(sizeValue, .cgSize, &size)
        
        return (position: position, size: size)
    }
    
    private func convertWindowFrameToScreenCoordinates(_ windowFrame: CGRect, for screen: NSScreen) -> CGRect {
        let screenHeight = NSScreen.screens.reduce(0) { max($0, $1.frame.maxY) }
        let flippedOrigin = CGPoint(x: windowFrame.origin.x, y: screenHeight - windowFrame.origin.y - windowFrame.height)
        return CGRect(origin: flippedOrigin, size: windowFrame.size)
    }
    
    deinit {
        workspaceNotificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }
}
