//
//  MediaManager.swift
//  NotchNook
//
//  Created by Lori Montenegro on 28/03/25.
//

import SwiftUI
import Defaults
import ScriptingBridge

@Observable
class MediaManager {
    
    static let shared = MediaManager()
    
    // MARK: - Constants
    
    private let SPOTIFY_BUNDLE_ID = "com.spotify.client"
    private let MUSIC_BUNDLE_ID = "com.apple.Music"
    
    // MARK: - Media State Properties
    
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
    
    // MARK: - Private Properties
    
    private var musicApp: MusicApplication?
    private var spotifyApp: SpotifyApplication?
    private var currentApp: SystemAppMeta?
    private var notificationObservers: [NSObjectProtocol] = []
    
    // MARK: - Polling Properties
    
    private var musicPollingTimer: Timer?
    private let musicPollingInterval: TimeInterval = 1.0
    
    // MARK: - Lifecycle
    
    private init() {
        setupApps()
        setupNotificationObservers()
    }
    
    deinit {
        // Stop polling timer
        stopMusicPolling()
        
        // Remove distributed notifications
        notificationObservers.forEach {
            DistributedNotificationCenter.default().removeObserver($0)
        }
        
        // Remove workspace notifications
        notificationObservers.forEach {
            NSWorkspace.shared.notificationCenter.removeObserver($0)
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupApps() {
        if let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == SPOTIFY_BUNDLE_ID }) {
            let spotify = SBApplication(processIdentifier: running.processIdentifier)
            spotify?.launchFlags = LSLaunchFlags()
            spotifyApp = spotify
        }
        
        if NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == MUSIC_BUNDLE_ID }) {
            musicApp = SBApplication(bundleIdentifier: MUSIC_BUNDLE_ID)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                _ = self.musicApp?.playerState
            }
        }
    }
    
    private func setupNotificationObservers() {
        startMusicPollingIfNeeded()
        
        setupSpotifyNotifications()
        setupWorkspaceNotifications()
        updateMediaInfo()
    }
    
    private func setupSpotifyNotifications() {
        let notifications = [
            ("com.spotify.client.PlaybackStateChanged", handleSpotifyStateChange),
            ("com.spotify.client.MetadataChanged", handleSpotifyStateChange)
        ]
        
        addDistributedObservers(for: notifications)
    }
    
    private func setupWorkspaceNotifications() {
        let notifications: [(NSNotification.Name, (Notification) -> Void)] = [
            (NSWorkspace.didLaunchApplicationNotification, handleAppLaunchNotification),
            (NSWorkspace.didTerminateApplicationNotification, handleAppTerminationNotification)
        ]
        
        for (name, handler) in notifications {
            let observer = NSWorkspace.shared.notificationCenter
                .addObserver(forName: name, object: nil, queue: .main, using: handler)
            notificationObservers.append(observer)
        }
    }
    
    private func addDistributedObservers(for notifications: [(String, (Notification) -> Void)]) {
        for (name, handler) in notifications {
            let observer = DistributedNotificationCenter.default()
                .addObserver(forName: NSNotification.Name(name), object: nil, queue: .main, using: handler)
            notificationObservers.append(observer)
        }
    }
    
    // MARK: - App Management

    private func handleAppLaunch(_ bundleId: String) {
        if bundleId == SPOTIFY_BUNDLE_ID {
            // Create instance only after app is fully launched
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                if let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == self?.SPOTIFY_BUNDLE_ID }) {
                    let spotify = SBApplication(processIdentifier: running.processIdentifier)
                    spotify?.launchFlags = LSLaunchFlags()
                    self?.spotifyApp = spotify
                }
                self?.updateMediaInfo()
            }
        } else if bundleId == MUSIC_BUNDLE_ID {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.musicApp = SBApplication(bundleIdentifier: bundleId)
                self?.startMusicPollingIfNeeded()
            }
        }
    }
    
    private func handleAppTermination(_ bundleId: String) {
        if bundleId == SPOTIFY_BUNDLE_ID {
            spotifyApp = nil
            if currentApp?.bundleId == SPOTIFY_BUNDLE_ID {
                DispatchQueue.main.async { [weak self] in
                    self?.resetTrackState()
                    self?.updateMediaInfo()
                }
            }
        } else if bundleId == MUSIC_BUNDLE_ID {
            stopMusicPolling()
            if currentApp?.bundleId == MUSIC_BUNDLE_ID {
                DispatchQueue.main.async { [weak self] in
                    self?.resetTrackState()
                }
            }
        }
    }
    
    // MARK: - Music Polling
    
    private func startMusicPollingIfNeeded() {
        stopMusicPolling()
        
        guard musicApp != nil else { return }
        
        musicPollingTimer = Timer.scheduledTimer(withTimeInterval: musicPollingInterval, repeats: true) { [weak self] _ in
            guard let self = self,
                  let music = self.musicApp,
                  music.isRunning else {
                self?.stopMusicPolling()
                return
            }
            
            let isMusicRunning = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == self.MUSIC_BUNDLE_ID }
            
            if isMusicRunning {
                self.updateMediaInfo()
            }
        }
    }
    
    private func stopMusicPolling() {
        musicPollingTimer?.invalidate()
        musicPollingTimer = nil
    }
    
    // MARK: - Notification Handlers
    
    private func handleSpotifyStateChange(_ notification: Notification) {
        updateMediaInfo()
    }
    
    private func handleAppLaunchNotification(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier,
              bundleId == SPOTIFY_BUNDLE_ID || bundleId == MUSIC_BUNDLE_ID
        else { return }
        handleAppLaunch(bundleId)
    }
    
    private func handleAppTerminationNotification(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else { return }
        handleAppTermination(bundleId)
    }
    
    // MARK: - Media Info Management
    
    private func updateMediaInfo() {
        let isMusicRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == MUSIC_BUNDLE_ID
        }
        
        let isSpotifyRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == SPOTIFY_BUNDLE_ID
        }
        
        guard isMusicRunning || isSpotifyRunning else {
            resetTrackState()
            return
        }
        
        if isSpotifyRunning, let spotify = spotifyApp {
            if let track = spotify.currentTrack, let playerState = spotify.playerState {
                let isPlaying = playerState == .playing
                let appMeta = SystemAppMeta(bundleId: SPOTIFY_BUNDLE_ID)
                updateTrackInfo(title: track.name, artist: track.artist, album: track.album, isPlaying: isPlaying, artworkURL: track.artworkUrl, app: appMeta)
                return
            }
        }
        
        if isMusicRunning, let music = musicApp, music.isRunning {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if let track = music.currentTrack, let playerState = music.playerState {
                    let isPlaying = playerState == .playing
                    let artwork = track.artworks?().firstObject as? MusicArtwork
                    let appMeta = SystemAppMeta(bundleId: self.MUSIC_BUNDLE_ID)
                    
                    self.updateTrackInfo(title: track.name, artist: track.artist, album: track.album, isPlaying: isPlaying, artwork: artwork, app: appMeta)
                } else {
                    self.resetTrackState()
                }
            }
            return
        }
        
        resetTrackState()
    }
    
    private func updateTrackInfo(title: String?, artist: String?, album: String?, isPlaying: Bool, artworkURL: String? = nil, artwork: MusicArtwork? = nil, app: SystemAppMeta) {
        var newTrack = Track()
        newTrack.title = title ?? ""
        newTrack.artist = artist ?? ""
        newTrack.album = album ?? ""
        newTrack.mediaApp = app
        
        let playingStateChanged = self.isPlaying != isPlaying
        let trackChanged = self.track.isValidReplacement(newTrack)
        
        guard playingStateChanged || trackChanged else { return }
        
        // Handle artwork
        if let artworkURL = artworkURL {
            if let cachedImage = ArtworkCache.shared.image(for: artworkURL) {
                newTrack.albumArt = cachedImage
            } else if let url = URL(string: artworkURL) {
                // Only load new artwork if track changed
                if trackChanged {
                    let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                        guard let self = self,
                              let data = data,
                              let image = NSImage(data: data) else {
                            return
                        }
                        
                        ArtworkCache.shared.store(image, for: artworkURL)
                        
                        DispatchQueue.main.async {
                            // Verify track hasn't changed while loading
                            if self.track.title == title && self.track.artist == artist {
                                self.track.albumArt = image
                            }
                        }
                    }
                    task.priority = URLSessionTask.highPriority
                    task.resume()
                }
            }
        } else if let artwork = artwork {
            // Only load new artwork if track changed
            if trackChanged {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let image = artwork.data else { return }
                    
                    DispatchQueue.main.async {
                        // Verify track hasn't changed while loading
                        if self?.track.title == title && self?.track.artist == artist {
                            self?.track.albumArt = image
                        }
                    }
                }
            }
        }
        
        // Update UI only if necessary
        DispatchQueue.main.async {
            if trackChanged {
                self.track = newTrack
            }
            if playingStateChanged {
                self.isPlaying = isPlaying
            }
            if trackChanged || playingStateChanged {
                self.currentApp = app
                self.updateLiveActivities()
            }
        }
    }
    
    private func resetTrackState() {
        DispatchQueue.main.async {
            self.track = .empty
            self.isPlaying = false
            self.currentApp = nil
            self.updateLiveActivities()
        }
    }
    
    // MARK: - Player Controls
    
    func togglePlayPause() {
        switch currentApp?.bundleId {
            case SPOTIFY_BUNDLE_ID:
                guard let spotify = spotifyApp, spotify.isRunning else { return }
                spotify.playpause?()
            case MUSIC_BUNDLE_ID:
                guard let music = musicApp, music.isRunning else { return }
                music.playpause?()
            default:
                break
        }
    }
    
    func goToPreviousTrack() {
        switch currentApp?.bundleId {
            case SPOTIFY_BUNDLE_ID:
                guard let spotify = spotifyApp, spotify.isRunning else { return }
                spotify.previousTrack?()
            case MUSIC_BUNDLE_ID:
                guard let music = musicApp, music.isRunning else { return }
                music.previousTrack?()
            default:
                break
        }
    }
    
    func goToNextTrack() {
        switch currentApp?.bundleId {
            case SPOTIFY_BUNDLE_ID:
                guard let spotify = spotifyApp, spotify.isRunning else { return }
                spotify.nextTrack?()
            case MUSIC_BUNDLE_ID:
                guard let music = musicApp, music.isRunning else { return }
                music.nextTrack?()
            default:
                break
        }
    }
    
    // MARK: - Live Activities
    
    private func updateLiveActivities() {
        if track != .empty {
            if !isPlaying { return }
            ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.media)
        } else {
            ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.media)
        }
    }
}

// MARK: - Artwork Cache

private class ArtworkCache {
    static let shared = ArtworkCache()
    
    private var cache = NSCache<NSString, NSImage>()
    
    func image(for url: String) -> NSImage? {
        return cache.object(forKey: url as NSString)
    }
    
    func store(_ image: NSImage, for url: String) {
        cache.setObject(image, forKey: url as NSString)
    }
}
