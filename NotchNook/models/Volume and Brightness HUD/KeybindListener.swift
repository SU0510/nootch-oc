//
//  KeybindListener.swift
//  NotchNook
//
//  Created by Ethan Bills on 7/19/24.
//

import Cocoa

class KeybindListener {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    init() {}
    
    deinit {
        stop()
    }
    
    private func checkAccessibilityPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
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
        
        let eventMask = (1 << NX_SYSDEFINED)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let listener = refcon?.load(as: KeybindListener.self) else { return Unmanaged.passUnretained(event) }
                return listener.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("Keybind listener started")
    }
    
    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        print("Keybind listener stopped")
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type.rawValue == NX_SYSDEFINED else { return Unmanaged.passUnretained(event) }
        
        guard let nsEvent = NSEvent(cgEvent: event) else { return Unmanaged.passUnretained(event) }
        
        if nsEvent.subtype.rawValue == NX_SUBTYPE_AUX_CONTROL_BUTTONS {
            let data = nsEvent.data1
            let keyCode = (data & 0xFFFF0000) >> 16
            if let mediaKey = MediaKey(rawValue: Int32(keyCode)) {
                handleMediaKey(mediaKey, event: nsEvent)
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func handleMediaKey(_ mediaKey: MediaKey, event: NSEvent) {
        let keyState = event.data1 & 0x0000FFFF
        let keyPressed = (keyState & 0xFF00) >> 8 == 0x0A
        
        guard keyPressed else { return }
        
        switch mediaKey {
        case .brightnessUp, .brightnessDown:
            // we need to delay this so the OS has time to process the change (brightness or volume)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.025) {
                do {
                    let newBrightness = try BrightnessCoordinator.getDisplayBrightness()
                    print(newBrightness)
                } catch {
                    print("Error fetching brightness: \(error)")
                }
            }
        case .volumeUp, .volumeDown, .mute:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.025) {
                do {
                    let newVolume = try SoundCoordinator.getSoundVolume()
                    print(newVolume)
                } catch {
                    print("Failed to get volume: \(error)")
                }
            }
        }
    }
}

enum MediaKey: Int32 {
    case brightnessUp = 2
    case brightnessDown = 3
    case mute = 7
    case volumeDown = 1
    case volumeUp = 0
}
