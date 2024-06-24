//
//  MediaApp.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//

import SwiftUI
import ScriptingBridge
import Defaults

@Observable
class BaseMediaApp<App: SBApplicationProtocol>: MediaApp {
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
    
    func doSafeCrossBridgeAction(_ action: @escaping () -> ()) {
        Task { [action] in
            if (app?.isRunning ?? false) { action() }
        }
    }
}
