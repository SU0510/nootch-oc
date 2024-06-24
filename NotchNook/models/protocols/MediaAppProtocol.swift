//
//  MediaAppProtocol.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import ScriptingBridge
import AppKit

protocol MediaApp: AnyObject {
    var meta: MediaAppMeta { get set }
    var isAppRunning: Bool { get set }
    var isPlaying: Bool { get set }
    var track: Track { get set }
    var notificationMonitor: NotificationObserverHelper? { get set }
    var appRunningMonitor: AppMonitor? { get set }
    var liveActivityTimer: Timer? { get set }
    var inactiveLiveActivitiesTimeout: Double { get set }
    
    func doSafeCrossBridgeAction(_ action: @escaping () -> ()) -> ()
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
            doThisAfter(0) { self.isAppRunning = true }
        }, onAppTerminate: {
            doThisAfter(0) { self.isAppRunning = false }
        })
    }
    
    func monitorTrackChange() {
        self.notificationMonitor = NotificationObserverHelper(notificationName: meta.notification) { sender in
            guard sender.userInfo?["Player State"] as? String != "Stopped" else {
                var newTrack = Track()
                newTrack.title = Track.empty.title
                newTrack.artist = Track.empty.artist
                newTrack.albumArt = NSImage()
                self.track = newTrack
                return
            }

            self.updateIsPlaying()
            DispatchQueue.global(qos: .utility).async {
                self.updateTrack()
            }
        }
    }
    
    func updateLiveActivities(_ altIsPlaying: Bool? = nil) {
        if altIsPlaying ?? self.isPlaying {
            NotchNook.shared.activeLiveActivities.insert(.media)
        } else {
            NotchNook.shared.activeLiveActivities.remove(.media)
        }
    }
}
