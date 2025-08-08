//
//  MediaManager.swift
//  NotchNook
//
//  Created by Lori Montenegro on 25/06/25.
//

import SwiftUI
import Defaults
import MediaRemoteAdapter

@Observable
class MediaManager {
    static let shared = MediaManager()
    
    var isPlaying: Bool = false {
        willSet {
            let timerId = "pauseLiveActivityDismiss"
            let inactivityTimeout = Defaults[.liveActivitiesSettings].inactivityTimeoutInSecs
            if isPlaying != newValue {
                if newValue {
                    TimersManager.shared.removeTimer(timerId)
                } else {
                    TimersManager.shared.addTimer(timerId, delay: inactivityTimeout) { _ in
                        ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.media)
                    }
                }
            }
        }
    }
    
    var track: Track = .empty
    var preferredMediaSource: MediaSource = Defaults[.generalSettings].preferredMediaSource
    
    private var mediaController: MediaController
    private var appRunningCheckTimer: Timer?
    
    private var lastTrackUpdate: TimeInterval = 0
    private var lastAppCheck: TimeInterval = 0
    private var scriptCooldowns: [String: TimeInterval] = [:]
    private var throttledTrackUpdate: (() -> Void)?
    private var lastReceivedTrackInfo: TrackInfo?
    
    private let trackUpdateInterval: TimeInterval = 1.0
    private let appCheckInterval: TimeInterval = 10.0
    private let scriptCooldownInterval: TimeInterval = 2.0
    
    // MARK: Lifecycle
    
    private init() {
        mediaController = MediaController()
        setupMediaControllerListeners()
        reconfigureMediaController()
    }
    
    deinit {
        mediaController.stopListening()
    }
    
    // MARK: Listeners and timers
    
    private func setupMediaControllerListeners() {
        throttledTrackUpdate = throttleWithTrailing(interval: 1.0) { [weak self] in
            guard let self = self else { return }
            if let trackInfo = self.lastReceivedTrackInfo {
                self.handleTrackInfoUpdate(trackInfo)
            }
        }
        
        mediaController.onTrackInfoReceived = { [weak self] trackInfo in
            self?.lastReceivedTrackInfo = trackInfo
            self?.throttledTrackUpdate?()
        }
        
        mediaController.onListenerTerminated = { [weak self] in
            DispatchQueue.main.async {
                self?.reset()
            }
        }
    }
    
    func throttleWithTrailing(interval: TimeInterval, queue: DispatchQueue = .main, action: @escaping () -> Void) -> () -> Void {
        var lastExecutionTime: TimeInterval = 0
        var workItem: DispatchWorkItem?
        
        return {
            let now = Date().timeIntervalSince1970
            let timeSinceLast = now - lastExecutionTime
            
            workItem?.cancel()
            
            if timeSinceLast >= interval {
                lastExecutionTime = now
                action()
            } else {
                let delay = interval - timeSinceLast
                workItem = DispatchWorkItem {
                    lastExecutionTime = Date().timeIntervalSince1970
                    action()
                }
                queue.asyncAfter(deadline: .now() + delay, execute: workItem!)
            }
        }
    }
    
    /// Workaround for when not detecting app closure
    private func startAppRunningMonitor() {
        appRunningCheckTimer?.invalidate()
        appRunningCheckTimer = Timer.scheduledTimer(withTimeInterval: appCheckInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date().timeIntervalSince1970
            guard now - self.lastAppCheck >= self.appCheckInterval else { return }
            self.lastAppCheck = now
            
            if self.resetIfNeeded() {
                self.appRunningCheckTimer?.invalidate()
                self.appRunningCheckTimer = nil
            }
        }
    }
    
    // MARK: Update methods
    
    private func handleTrackInfoUpdate(_ trackInfo: TrackInfo) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let track = trackInfo.payload
            
            if let isPlaying = track.isPlaying {
                updateTrackInfo(title: track.title, artist: track.artist, album: track.album, isPlaying: isPlaying, albumArtImage: track.artwork, appName: track.applicationName, bundleIdentifier: track.bundleIdentifier)
            } else {
                reset()
            }
        }
    }
    
    private func updateTrackInfo(title: String?, artist: String?, album: String?, isPlaying: Bool, albumArtImage: NSImage?, appName: String?, bundleIdentifier: String?) {
        var newTrack = Track()
        newTrack.title = title ?? ""
        newTrack.artist = artist ?? ""
        newTrack.album = album ?? ""
        newTrack.albumArt = albumArtImage ?? NSImage()
        newTrack.appName = appName ?? ""
        newTrack.appBundleId = bundleIdentifier ?? ""
        newTrack.browserBundleId = BrowserType.getBrowserBundleId(for: appName ?? "")
        
        let playingStateChanged = self.isPlaying != isPlaying
        let trackChanged = self.track.isValidReplacement(newTrack)
        
        guard playingStateChanged || trackChanged else { return }
        
        // Update UI only if necessary
        DispatchQueue.main.async {
            if trackChanged {
                self.track = newTrack
                self.startAppRunningMonitor()
            }
            if playingStateChanged {
                self.isPlaying = isPlaying
            }
            if trackChanged || playingStateChanged {
                self.updateLiveActivities()
            }
        }
    }
    
    private func updateLiveActivities() {
        if track != .empty {
            if !isPlaying { return }
            ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.media)
        } else {
            ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.media)
        }
    }
    
    // MARK: Private helpers
    
    private func runAppleScript(script: String) {
        // Caching mechanism for script executions: prevents duplicate/rapid script executions
        let now = Date().timeIntervalSince1970
        if let lastExec = scriptCooldowns[script], now - lastExec < scriptCooldownInterval {
            return
        }
        scriptCooldowns[script] = now
        
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("Error running AppleScript: \(error)")
        }
    }
    
    private func resetIfNeeded() -> Bool {
        let appName = track.appName
        if appName.isEmpty { return true }
        
        let isRunning = isAppRunning(appName)
        if !isRunning {
            reconfigureMediaController()
            return true
        }
        
        return false
    }
    
    private func isAppRunning(_ appName: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.localizedName?.contains(appName) == true
        }
    }
    
    // MARK: Public methods
    
    func reset() {
        DispatchQueue.main.async {
            self.track = .empty
            self.isPlaying = false
            ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.media)
            self.mediaController.stopListening()
        }
    }
    
    func isLikelyBrowserApp() -> Bool {
        preferredMediaSource == .systemWide && track.browserBundleId != nil
    }
    
    func reconfigureMediaController() {
        reset()
        
        switch preferredMediaSource {
            case .systemWide:
                mediaController = MediaController(bundleIdentifier: nil)
            case .appleMusic, .spotify:
                mediaController = MediaController(bundleIdentifier: preferredMediaSource.bundleIdentifier)
        }
        
        setupMediaControllerListeners()
        mediaController.startListening()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self, self.track == .empty else { return }
            
            if preferredMediaSource != .systemWide {
                // prevent from force opening the media app
                guard isAppRunning(preferredMediaSource.name) else {
                    setupMediaControllerListeners()
                    mediaController.startListening()
                    updateLiveActivities()
                    return
                }
            }
            self.forceMediaControllerRestart()
        }
    }
    
    func forceMediaControllerRestart(appName: String? = nil) {
        mediaController.stopListening()
        
        let appName = appName != nil ? "\"\(appName!)\"" : preferredMediaSource.name
        runAppleScript(script: "tell application \(appName) to playpause")
        
        mediaController = MediaController(bundleIdentifier: preferredMediaSource.bundleIdentifier)
        setupMediaControllerListeners()
        mediaController.startListening()
        
        runAppleScript(script: "tell application \(appName) to playpause")
        
        updateLiveActivities()
    }
    
    func togglePlayPause() {
        switch preferredMediaSource {
            case .systemWide:
                mediaController.togglePlayPause()
            case .appleMusic, .spotify:
                runAppleScript(script: "tell application \(preferredMediaSource.name) to playpause")
        }
    }
    
    func goToPreviousTrack() {
        switch preferredMediaSource {
            case .systemWide:
                mediaController.previousTrack()
            case .appleMusic, .spotify:
                runAppleScript(script: "tell application \(preferredMediaSource.name) to previous track")
        }
    }
    
    func goToNextTrack() {
        switch preferredMediaSource {
            case .systemWide:
                mediaController.nextTrack()
            case .appleMusic, .spotify:
                runAppleScript(script: "tell application \(preferredMediaSource.name) to next track")
        }
    }
    
    func openApp() {
        guard let browserBundleId = track.browserBundleId else {
            SystemAppMeta(bundleId: track.appBundleId).openApp()
            return
        }
        SystemAppMeta(bundleId: browserBundleId).openApp()
    }
}
