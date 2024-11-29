//
//  VolumeAndBrightnessListener.swift
//  NotchNook
//
//  Created by Ethan Bills on 7/19/24.
//

import Cocoa
import CoreGraphics

class VolumeAndBrightnessListener: NSObject, MediaKeyTapDelegate {
    static let shared = VolumeAndBrightnessListener()
    
    private var mediaKeyTap: MediaKeyTap?
    private var sideEffects = [String: ((MediaKey) -> Void)]()
    private var HUDCloseWorkItem: DispatchWorkItem?
    private var HUDCloseTimer: Timer?
    
    private let lock = NSLock()
    
    private override init() {
        super.init()
    }
    
    func start() {
        lock.lock()
        defer { lock.unlock() }
        
        guard mediaKeyTap == nil else { return }
        
        mediaKeyTap = MediaKeyTap(delegate: self)
        mediaKeyTap?.start()
        print("Media key monitoring started")
        
        startObservingSystemWakeUp()
        HUDManager.disableSystemHUD()
        attemptHUD()
    }
    
    deinit {
        cleanup()
    }
    
    private func cleanup() {
        stopBackgroundCloseHUD()
        stopObservingSystemWakeUp()
        
        if mediaKeyTap != nil {
            mediaKeyTap?.stop()
            mediaKeyTap = nil
        }
        
        sideEffects.removeAll()
    }
    
    func stop() {
        lock.lock()
        defer { lock.unlock() }

        cleanup()
        HUDManager.enableSystemHUD()
    }
    
    func addSideEffect(_ sideEffect: @escaping (MediaKey) -> Void, for id: String) {
        sideEffects[id] = sideEffect
    }
    
    func removeSideEffect(for id: String) {
        sideEffects.removeValue(forKey: id)
    }
    
    // MARK: - MediaKeyTapDelegate
    
    func handle(mediaKey: MediaKey, event: KeyEvent?, modifiers: NSEvent.ModifierFlags?) {
        sideEffects.values.forEach { sideEffect in
            sideEffect(mediaKey)
        }
    }
    
    // MARK: - HUD Management
    
    private func attemptHUD() {
        HUDCloseWorkItem = DispatchWorkItem { [weak self] in
            guard self != nil else { return }
            HUDManager.disableSystemHUD()
        }
        
        HUDCloseTimer = Timer.scheduledTimer(withTimeInterval: 2100, repeats: true) { [weak self] _ in
            if let workItem = self?.HUDCloseWorkItem {
                DispatchQueue.global().async(execute: workItem)
            }
        }
    }
    
    private func stopBackgroundCloseHUD() {
        HUDCloseWorkItem?.cancel()
        HUDCloseWorkItem = nil
        HUDCloseTimer?.invalidate()
        HUDCloseTimer = nil
    }
    
    // MARK: - System Wake Observation
    
    private var systemWakeUpMonitor: Any?
    private var screenWakeUpMonitor: Any?
    
    private func startObservingSystemWakeUp() {
        systemWakeUpMonitor = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            HUDManager.disableSystemHUD()
        }
        
        screenWakeUpMonitor = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            HUDManager.disableSystemHUD()
        }
    }
    
    private func stopObservingSystemWakeUp() {
        if let observer = systemWakeUpMonitor {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = screenWakeUpMonitor {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
}
