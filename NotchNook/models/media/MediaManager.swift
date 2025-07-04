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
        mediaController.onTrackInfoReceived = { [weak self] trackInfo in
            self?.handleTrackInfoUpdate(trackInfo)
        }
        
        mediaController.onListenerTerminated = { [weak self] in
            DispatchQueue.main.async {
                self?.resetTrackState()
            }
        }
    }
        
    /// Workaround for when not detecting app closure
    private func startAppRunningMonitor() {
        appRunningCheckTimer?.invalidate()
        appRunningCheckTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.resetIfNeeded() {
                appRunningCheckTimer?.invalidate()
                appRunningCheckTimer = nil
            }
        }
    }
    
    // MARK: Update methods
    
    private func handleTrackInfoUpdate(_ trackInfo: TrackInfo) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let track = trackInfo.payload

            if let isPlaying = track.isPlaying {
                updateTrackInfo(title: track.title, artist: track.artist, album: track.album, isPlaying: isPlaying, albumArtImage: track.artwork, appName: track.applicationName)
            } else {
                resetTrackState()
            }
        }
    }
    
    private func updateTrackInfo(title: String?, artist: String?, album: String?, isPlaying: Bool, albumArtImage: NSImage?, appName: String?) {
        var newTrack = Track()
        newTrack.title = title ?? ""
        newTrack.artist = artist ?? ""
        newTrack.album = album ?? ""
        newTrack.albumArt = albumArtImage ?? NSImage()
        newTrack.appName = appName ?? ""
        
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
    
    private func resetTrackState() {
        DispatchQueue.main.async {
            self.track = .empty
            self.isPlaying = false
            self.updateLiveActivities()
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
    
    private func forceMediaControllerRestart() {
        guard isAppRunning(preferredMediaSource.name) else { return }
        mediaController.stopListening()
        
        mediaController = MediaController(bundleIdentifier: preferredMediaSource.bundleIdentifier)
        setupMediaControllerListeners()
        mediaController.startListening()
        
        runAppleScript(script: "tell application \(preferredMediaSource.name) to playpause")
        runAppleScript(script: "tell application \(preferredMediaSource.name) to playpause")
        
        updateLiveActivities()
    }
    
    private func runAppleScript(script: String) {
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
        if appName.isEmpty { return false }
        
        let isRunning = isAppRunning(appName)
        if !isRunning {
            resetTrackState()
            mediaController.stopListening()
            return true
        }
        
        return false
    }
    
    private func isAppRunning(_ appName: String) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains { app in
            guard let name = app.localizedName else { return false }
            return name.contains(appName)
        }
        
        return isRunning
    }
    
    // MARK: Media Controls
    
    func reconfigureMediaController() {
        resetTrackState()
        mediaController.stopListening()
        
        switch preferredMediaSource {
            case .systemWide:
                mediaController = MediaController(bundleIdentifier: nil)
            case .appleMusic, .spotify:
                mediaController = MediaController(bundleIdentifier: preferredMediaSource.bundleIdentifier)
        }
        
        setupMediaControllerListeners()
        mediaController.startListening()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            if self.track == .empty {
                self.forceMediaControllerRestart()
            }
        }
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
        runAppleScript(script: "tell application \"\(track.appName)\" to activate reopen")
    }
}
