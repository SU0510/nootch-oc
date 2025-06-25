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
            if isPlaying != newValue {
                if newValue {
                    TimersManager.shared.removeTimer(timerId)
                } else {
                    TimersManager.shared.addTimer(timerId, delay: Defaults[.liveActivitiesSettings].inactivityTimeoutInSecs) { _ in
                        ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.media)
                    }
                }
            }
        }
    }
    
    var track: Track = .empty
    
    var preferredMediaSource: MediaSource = .systemWide {
        didSet {
            reconfigureMediaController()
        }
    }
    
    private var mediaController: MediaController
    
    // MARK: Lifecycle
    
    private init() {
        mediaController = MediaController()
        setupMediaControllerListeners()
        reconfigureMediaController()
    }
    
    deinit {
        mediaController.stopListening()
    }
    
    // MARK: Private Methods
    
    private func setupMediaControllerListeners() {
        mediaController.onTrackInfoReceived = { [weak self] trackInfo in
            self?.handleTrackInfoUpdate(trackInfo)
        }
    }
    
    private func reconfigureMediaController() {
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
    
    private func handleTrackInfoUpdate(_ trackInfo: TrackInfo) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let track = trackInfo.payload

            if let isPlaying = track.isPlaying {
                updateTrackInfo(title: track.title, artist: track.artist, album: track.album, isPlaying: isPlaying, albumArtImage: track.artwork, albumArtId: track.artworkDataBase64)
            } else {
                resetTrackState()
            }
        }
    }
    
    private func updateTrackInfo(title: String?, artist: String?, album: String?, isPlaying: Bool, albumArtImage: NSImage?, albumArtId: String?) {
        var newTrack = Track()
        newTrack.title = title ?? ""
        newTrack.artist = artist ?? ""
        newTrack.album = album ?? ""
        newTrack.albumArt = albumArtImage ?? NSImage()
        
        let playingStateChanged = self.isPlaying != isPlaying
        let trackChanged = self.track.isValidReplacement(newTrack)
        
        guard playingStateChanged || trackChanged else { return }
        
        // Update UI only if necessary
        DispatchQueue.main.async {
            if trackChanged {
                self.track = newTrack
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
    
    // MARK: Media Controls
    
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
}
