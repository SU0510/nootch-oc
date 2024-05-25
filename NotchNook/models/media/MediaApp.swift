//
//  MediaApp.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//

import SwiftUI
import ScriptingBridge

protocol MediaApp: AnyObject {
    var meta: MediaAppMeta { get set }
    var isAppRunning: Bool { get set }
    var isPlaying: Bool { get set }
    var track: Track { get set }
    var notificationMonitor: NotificationObserverHelper? { get set }
    var appRunningMonitor: AppMonitor? { get set }
    var liveActivityTimer: Timer? { get set }
    
    //    func getTrackInformation() -> Track
//    init()
//    init(meta: MediaAppMeta)
    func updateIsPlaying() -> ()
    func updateTrack() -> ()
    func toggleIsPlaying() -> ()
    func prevTrack() -> ()
    func nextTrack() -> ()
    func toggleLovedInTrack() -> ()
    func monitorAppIsRunning() -> ()
    func monitorTrackChange() -> ()
    func setupApp() -> ()
    func updateLiveActivities(_ isPlaying: Bool?) -> ()
}

extension MediaApp {
    func monitorAppIsRunning() {
        self.appRunningMonitor = AppMonitor(bundleID: meta.bundleID, onAppLaunch: {
            self.isAppRunning = true
        }, onAppTerminate: {
            self.isAppRunning = false
        })
    }
    
    func monitorTrackChange() {
        self.notificationMonitor = NotificationObserverHelper(notificationName: meta.notification) { sender in
            guard sender.userInfo?["Player State"] as? String != "Stopped" else {
                var newTrack = Track()
                newTrack.title = ""
                newTrack.artist = ""
                newTrack.albumArt = NSImage()
                self.track = newTrack
                return
            }
//            print("brico")
            
            self.updateIsPlaying()
            DispatchQueue.global(qos: .userInteractive).async {
                self.updateTrack()
            }
        }
    }
    
    func updateLiveActivities(_ altIsPlaying: Bool? = nil) {
        withAnimation(.bouncy(extraBounce: 0.075)) {
            if altIsPlaying ?? self.isPlaying {
                NotchNook.shared.activeLiveActions.insert(.media)
            } else {
                NotchNook.shared.activeLiveActions.remove(.media)
            }
        }
    }
}

@Observable
class BlankMediaApp<App: SBApplicationProtocol>: MediaApp {
    
    var meta: MediaAppMeta
    var isAppRunning: Bool {
        willSet {
            if !isAppRunning && newValue {
                self.setupApp()
            } else if isAppRunning && !newValue {
                self.isPlaying = false
                self.app = nil
            }
        }
    }
    var isPlaying: Bool {
        willSet {
            if !isPlaying && newValue {
                self.liveActivityTimer?.invalidate()
                DispatchQueue.main.async {
                    MediaPlayer.shared.connectedApp = self.meta
                    self.updateLiveActivities(newValue)
                }
            } else if isPlaying && !newValue {
                setupLiveActivityTimer()
            }
        }
    }
    var track: Track
    var notificationMonitor: NotificationObserverHelper?
    var appRunningMonitor: AppMonitor?
    var app: App? {
        didSet {
            if app != nil {
                self.updateIsPlaying()
                self.updateTrack()
            }
        }
    }
    var liveActivityTimer: Timer?
    
    init(meta: MediaAppMeta) {
        self.meta = meta
        self.isAppRunning = false
        self.isPlaying = false
        self.track = .empty
        self.notificationMonitor = nil
        self.appRunningMonitor = nil
        self.updateTrack()
        self.updateIsPlaying()
        self.updateLiveActivities(self.isPlaying)
        self.monitorAppIsRunning()
        self.monitorTrackChange()
    }
    
    func setupLiveActivityTimer() {
        self.liveActivityTimer?.invalidate()
        self.liveActivityTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            self.updateLiveActivities()
        }
    }
    
    func setupApp() { if let app = SBApplication(bundleIdentifier: self.meta.bundleID) as? App { self.app = app } }
    
    func updateIsPlaying() { }
    
    func updateTrack() { }
    
    func toggleIsPlaying() { }
    
    func prevTrack() { }
    
    func nextTrack() { }
    
    func toggleLovedInTrack() { }
}
