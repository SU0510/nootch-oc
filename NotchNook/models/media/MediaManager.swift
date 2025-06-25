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
            
            if let isPlaying = trackInfo.payload.isPlaying {
                self.isPlaying = isPlaying
            }
            
            if !(trackInfo.payload.title ?? "").isEmpty {
                var newTrack = Track()
                newTrack.title = trackInfo.payload.title ?? ""
                newTrack.artist = trackInfo.payload.artist ?? ""
                newTrack.album = trackInfo.payload.album ?? ""
                newTrack.albumArt = trackInfo.payload.artwork ?? NSImage()
                
                if newTrack != self.track {
                    self.track = newTrack
                }
            }
            
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
