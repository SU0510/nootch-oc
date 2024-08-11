//
//  VolumeAndBrightnessListener.swift
//  NotchNook
//
//  Created by Ethan Bills on 7/19/24.
//

import Cocoa
import CoreGraphics

enum MediaKey: Int32 {
    case brightnessUp = 2
    case brightnessDown = 3
    case volumeUp = 0
    case volumeDown = 1
    case mute = 7
}

struct KeyEvent {
    let keycode: Int32
    let keyFlags: Int32
    let keyPressed: Bool
    let keyRepeat: Bool
}


class VolumeAndBrightnessListener {
    static let shared = VolumeAndBrightnessListener()
    private var sideEffects = [String:((MediaKey) -> ())]()
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    private init() {}
    
    deinit {
        stop()
    }
    
    func start() {
        if !VolumeAndBrightnessListener.checkAccessibilityPermissions() {
            MessageUtil.showMessage(
                title: "Accessibility Permissions Required",
                message: "This app requires accessibility permissions to intercept brightness and volume buttons. Would you like to open the settings (this will quit the app)?"
            ) { action in
                switch action {
                case .ok:
                    SystemIntegrationHelper.openAccessibilityPreferences()
                    SystemIntegrationHelper.quitApp()
                case .cancel:
                    print("User cancelled. App may not function properly.")
                }
            }
            return
        }
        
        if globalMonitor == nil && localMonitor == nil {
            HUDManager.disableSystemHUD()
            startMonitoringMediaKeys()
        }
    }
    
    func addSideEffect(_ sideEffect: @escaping (MediaKey) -> (), for id: String) {
        sideEffects[id] = { [weak self] mediaKey in
            guard self != nil else { return }
            sideEffect(mediaKey)
        }
    }
    
    func removeSideEffect(for id: String) {
        sideEffects.removeValue(forKey: id)
    }
    
    static func checkAccessibilityPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    func stop() {
        HUDManager.enableSystemHUD()
        stopMonitoringMediaKeys()
    }
    
    private func startMonitoringMediaKeys() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .systemDefined) { [weak self] event in
            self?.handleEvent(event)
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .systemDefined) { [weak self] event in
            self?.handleEvent(event)
            return event
        }
        
        print("Media key listener started")
    }
    
    private func stopMonitoringMediaKeys() {
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        
        globalMonitor = nil
        localMonitor = nil
        
        print("Media key listener stopped")
    }
    
    private func handleEvent(_ event: NSEvent) {
        guard let keyEvent = event.keyEvent else {
            return
        }
        
        guard event.isMediaKeyEvent, keyEvent.keyPressed else {
            return
        }
        
        if let mediaKey = MediaKey(rawValue: Int32(keyEvent.keycode)) {
            sideEffects.values.forEach { $0(mediaKey )}
        }
    }
}

// MARK: - Extensions

extension NSEvent {
    var isKeyEvent: Bool {
        return subtype.rawValue == 8
    }
    
    var keyEvent: KeyEvent? {
        guard type == .systemDefined && subtype.rawValue == 8 else {
            return nil
        }
        
        let keycode = Int32((data1 & 0xffff0000) >> 16)
        let keyFlags = Int32(data1 & 0x0000ffff)
        let keyPressed = ((keyFlags & 0xff00) >> 8) == 0xa
        let keyRepeat = (keyFlags & 0x1) == 0x1
        
        return KeyEvent(keycode: keycode, keyFlags: keyFlags, keyPressed: keyPressed, keyRepeat: keyRepeat)
    }
    
    var isMediaKeyEvent: Bool {
        let mediaKeys: [Int32] = [
            NX_KEYTYPE_PLAY,
            NX_KEYTYPE_PREVIOUS,
            NX_KEYTYPE_NEXT,
            NX_KEYTYPE_FAST,
            NX_KEYTYPE_REWIND,
            NX_KEYTYPE_SOUND_UP,
            NX_KEYTYPE_SOUND_DOWN,
            NX_KEYTYPE_MUTE,
            NX_KEYTYPE_BRIGHTNESS_UP,
            NX_KEYTYPE_BRIGHTNESS_DOWN
        ]
        return isKeyEvent && mediaKeys.contains(keyEvent!.keycode)
    }
}
