//
//  MediaApp.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//

import SwiftUI
import ScriptingBridge
import Defaults

protocol MediaApp: AnyObject {
    var meta: MediaAppMeta { get set }
    var isAppRunning: Bool { get set }
    var isPlaying: Bool { get set }
    var track: Track { get set }
    var notificationMonitor: NotificationObserverHelper? { get set }
    var appRunningMonitor: AppMonitor? { get set }
    var liveActivityTimer: Timer? { get set }
    var inactiveLiveActivitiesTimeout: Double { get set }

    func doSafeCrossBridgeAction(_ action: () -> ()) -> ()
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
            
            self.updateIsPlaying()
            DispatchQueue.global(qos: .userInteractive).async {
                self.updateTrack()
            }
        }
    }
    
    func updateLiveActivities(_ altIsPlaying: Bool? = nil) {
        withAnimation(TopBarView.animation) {
            if altIsPlaying ?? self.isPlaying {
                NotchNook.shared.activeLiveActivities.insert(.media)
            } else {
                NotchNook.shared.activeLiveActivities.remove(.media)
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
                doThisAfter(0) {
                    if MediaPlayer.shared.connectedApp == nil {
                        MediaPlayer.shared.connectedApp = self.meta
                    }
                }
            } else if isAppRunning && !newValue {
                doThisAfter(0) {
                    self.isPlaying = false
                    if MediaPlayer.shared.connectedApp == self.meta {
                        MediaPlayer.shared.connectedApp = nil
                        self.updateLiveActivities(newValue)
                    }
                }
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
            if let app, app.isRunning {
                self.updateIsPlaying()
                self.updateTrack()
            }
        }
    }
    var liveActivityTimer: Timer?
    var inactiveLiveActivitiesTimeout: Double
    var defaultsTasks = [Task<Void, Never>]()
    
    init(meta: MediaAppMeta) {
        self.meta = meta
        self.isAppRunning = false
        self.isPlaying = false
        self.track = .empty
        self.notificationMonitor = nil
        self.appRunningMonitor = nil
        self.inactiveLiveActivitiesTimeout = Defaults[.liveActivitiesSettings].inactivityTimeoutInSecs
        self.updateTrack()
        self.updateIsPlaying()
        self.updateLiveActivities(self.isPlaying)
        self.monitorAppIsRunning()
        self.monitorTrackChange()
        self.monitorDefaults()
    }
    
    deinit {
        self.unmonitorDefaults()
    }
    
    func monitorDefaults() {
        defaultsTasks.append(Task {
            for await value in Defaults.updates(.liveActivitiesSettings) {
                self.inactiveLiveActivitiesTimeout = value.inactivityTimeoutInSecs
            }
        })
    }
    
    func unmonitorDefaults() {
        defaultsTasks.forEach { task in
            task.cancel()
        }
    }
    
    func setupLiveActivityTimer() {
        self.liveActivityTimer?.invalidate()
        self.liveActivityTimer = Timer.scheduledTimer(withTimeInterval: self.inactiveLiveActivitiesTimeout, repeats: false) { _ in
            self.updateLiveActivities()
        }
    }
    
    func setupApp() {
        if self.app == nil, let app = SBApplication(bundleIdentifier: self.meta.bundleID) as? App { 
            self.app = app
        }
    }
    
    func updateIsPlaying() { }
    
    func updateTrack() { }
    
    func toggleIsPlaying() { }
    
    func prevTrack() { }
    
    func nextTrack() { }
    
    func toggleLovedInTrack() { }
    
    func doSafeCrossBridgeAction(_ action: () -> ()) {
        if (app?.isRunning ?? false) { action() }
    }
}
