//
//  KeybindListener.swift
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

class KeybindListener: NSObject {
    private var keyEventPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var runLoop: CFRunLoop?
    
    private let keysToWatch: [MediaKey] = [.brightnessUp, .brightnessDown, .volumeUp, .volumeDown, .mute]
    
    override init() {
        super.init()
    }
    
    deinit {
        stop()
    }
    
    func start() {
        if !checkAccessibilityPermissions() {
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
        
        do {
            try startWatchingMediaKeys()
        } catch {
            print("Failed to start watching media keys: \(error)")
        }
    }
    
    func stop() {
        stopWatchingMediaKeys()
    }
    
    private func checkAccessibilityPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    private func startWatchingMediaKeys() throws {
        let eventCallback: CGEventTapCallBack = { proxy, type, event, refcon in
            let listener = Unmanaged<KeybindListener>.fromOpaque(refcon!).takeUnretainedValue()
            return listener.handleCGEvent(type: type, event: event)
        }
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly, // Changed from .defaultTap to .listenOnly
            eventsOfInterest: CGEventMask(1 << NX_SYSDEFINED),
            callback: eventCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw EventTapError.eventTapCreationFailure
        }
        
        keyEventPort = eventTap
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        guard let source = runLoopSource else {
            throw EventTapError.runLoopSourceCreationFailure
        }
        
        runLoop = CFRunLoopGetCurrent()
        CFRunLoopAddSource(runLoop, source, .commonModes)
        
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("Media key listener started")
    }
    
    private func stopWatchingMediaKeys() {
        if let source = runLoopSource {
            CFRunLoopSourceInvalidate(source)
        }
        if let runLoop = runLoop {
            CFRunLoopStop(runLoop)
        }
        if let port = keyEventPort {
            CFMachPortInvalidate(port)
        }
        
        keyEventPort = nil
        runLoopSource = nil
        runLoop = nil
        
        print("Media key listener stopped")
    }
    
    private func handleCGEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type.rawValue == UInt32(NX_SYSDEFINED) else {
            return Unmanaged.passRetained(event)
        }
        
        guard let nsEvent = NSEvent(cgEvent: event) else {
            return Unmanaged.passRetained(event)
        }
        
        if nsEvent.isMediaKeyEvent {
            let keyEvent = nsEvent.keyEvent
            if let mediaKey = MediaKey(rawValue: keyEvent.keycode) {
                handleMediaKey(mediaKey, event: keyEvent)
            }
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func handleMediaKey(_ mediaKey: MediaKey, event: KeyEvent) {
        guard event.keyPressed else { return }
        
        switch mediaKey {
        case .brightnessUp, .brightnessDown:
            handleBrightnessChange()
        case .volumeUp, .volumeDown, .mute:
            handleVolumeChange()
        }
    }
    
    private func handleBrightnessChange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.015) {
            do {
                let newBrightness = try BrightnessCoordinator.getDisplayBrightness()
                GlobalBrightnessAndVolume.shared.brightness = Double(newBrightness)
            } catch {
                print("Error fetching brightness: \(error)")
            }
        }
    }
    
    private func handleVolumeChange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.015) {
            do {
                let newVolume = try SoundCoordinator.getSoundVolume()
//                let device = try SoundCoordinator.getAudioDeviceType()
                GlobalBrightnessAndVolume.shared.volume = Double(newVolume)
            } catch {
                print("Failed to get volume: \(error)")
            }
        }
    }
}

// MARK: - Extensions

extension NSEvent {
    var isKeyEvent: Bool {
        return subtype.rawValue == 8
    }
    
    var keycode: Int32 {
        return Int32((data1 & 0xffff0000) >> 16)
    }
    
    var keyEvent: KeyEvent {
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
        return isKeyEvent && mediaKeys.contains(keycode)
    }
}

enum EventTapError: Error {
    case eventTapCreationFailure
    case runLoopSourceCreationFailure
}
