//
//  ContentViewModel.swift
//  Jukebox
//
//  Created by Sasindu Jayasinghe on 13/10/21.
//

import Foundation
import SwiftUI
import ScriptingBridge

class MediaPlayer: ObservableObject {
    static let shared = MediaPlayer()
    
    // Music Applications
    var connectedApp = ConnectedApps.appleMusic
    var spotifyApp: SpotifyApplication?
    var appleMusicApp: MusicApplication?
    
    var name: String {
        connectedApp == .spotify ? Constants.Spotify.name : Constants.AppleMusic.name
    }
    
    var isRunning: Bool {
        connectedApp == .spotify ? spotifyApp?.isRunning ?? false : appleMusicApp?.isRunning ?? false
    }
    
    var notification: String {
        connectedApp == .spotify ? Constants.Spotify.notification : Constants.AppleMusic.notification
    }
    
    // Popover
    @Published var popoverIsShown = true
    
    // Track
    @Published var track = Track()
    @Published var isPlaying = false {
        didSet {
            updateLiveActivities()
        }
    }
    @Published var isLoved = false
    
    // Seeker
    @Published var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @Published var trackDuration: Double = 0
    @Published var seekerPosition: Double = 0
    
    private var observer: NSKeyValueObservation?
    
    init() {
        setupMusicApps()
        setupObservers()
        guard isRunning else { return }
        playStateOrTrackDidChange(nil)
        updateLiveActivities()
    }
    
    deinit {
        observer?.invalidate()
    }
    
    func updateLiveActivities() {
        withAnimation(.bouncy(extraBounce: 0.075)) {
            if isPlaying {
                if !NotchNook.shared.activeLiveActions.contains(.media) {
                    NotchNook.shared.activeLiveActions.insert(.media)
                }
            } else {
                if NotchNook.shared.activeLiveActions.contains(.media) {
                    NotchNook.shared.activeLiveActions.remove(.media)
                }
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupMusicApps() {
        print("Setting up music apps")
        switch connectedApp {
        case .spotify:
            guard spotifyApp == nil else { return }
            spotifyApp = SBApplication(bundleIdentifier: Constants.Spotify.bundleID)
        case .appleMusic:
            guard appleMusicApp == nil else { return }
            appleMusicApp = SBApplication(bundleIdentifier: Constants.AppleMusic.bundleID)
        }
    }
    
    private func setupObservers() {
        
//        observer = UserDefaults.standard.observe(\.connectedApp, options: [.old, .new]) { defaults, change in
//            DistributedNotificationCenter.default().removeObserver(self)
//            DistributedNotificationCenter.default().addObserver(
//                self,
//                selector: #selector(self.playStateOrTrackDidChange),
//                name: NSNotification.Name(rawValue: self.notification),
//                object: nil,
//                suspensionBehavior: .deliverImmediately)
//            self.setupMusicApps()
//            self.playStateOrTrackDidChange(nil)
//        }
                
        // ScriptingBridge Observer
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(playStateOrTrackDidChange),
            name: NSNotification.Name(rawValue: notification),
            object: nil,
            suspensionBehavior: .deliverImmediately)
        
        // Add observer to listen for popover open
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(popoverIsOpening),
            name: NSPopover.willShowNotification,
            object: nil)
        
        // Add observer to listen for popover close
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(popoverIsClosing),
            name: NSPopover.didCloseNotification,
            object: nil)
        
    }
    
    // MARK: - Notification Handlers
    
    @objc func playStateOrTrackDidChange(_ sender: NSNotification?) {
        setupMusicApps()
        guard isRunning, sender?.userInfo?["Player State"] as? String != "Stopped" else {
            self.track.title = ""
            self.track.artist = ""
            self.track.albumArt = NSImage()
            self.trackDuration = 0
            updateMenuBarText()
            return
        }
        
        print("The play state or the currently playing track changed")
        getPlayState()
        getTrackInformation()
    }
    
    // MARK: - Media & Playback
    
    private func getPlayState() {
        isPlaying = connectedApp == .spotify
        ? spotifyApp?.playerState == .playing
        : appleMusicApp?.playerState == .playing
    }
    
    func getTrackInformation() {
        
        print("Getting track information...")
        
        switch connectedApp {
        case .spotify:
            
            // Track
            self.track.title = spotifyApp?.currentTrack?.name ?? "Unknown Title"
            self.track.artist = spotifyApp?.currentTrack?.artist ?? "Unknown Artist"
            self.track.album = spotifyApp?.currentTrack?.album ?? "Unknown Album"
            if let artworkURLString = spotifyApp?.currentTrack?.artworkUrl,
               let url = URL(string: artworkURLString) {
                URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                    guard let data = data, error == nil else {
                        print(error!.localizedDescription)
                        return
                    }
                    DispatchQueue.main.async {
                        self?.track.albumArt = NSImage(data: data) ?? NSImage()
                    }
                    
                }.resume()
            }
            
            // Seeker
            self.trackDuration = Double(spotifyApp?.currentTrack?.duration ?? 0) / 1000
            
        case .appleMusic:
            
            // Track
            self.track.title = appleMusicApp?.currentTrack?.name ?? "Unknown Title"
            self.track.artist = appleMusicApp?.currentTrack?.artist ?? "Unknown Artist"
            self.track.album = appleMusicApp?.currentTrack?.album ?? "Unknown Album"
            self.isLoved = appleMusicApp?.currentTrack?.loved ?? false
            // Might have to change this later...
            var count = 0
            var waitForData: (() -> Void)!
            waitForData = {
                let art = self.appleMusicApp?.currentTrack?.artworks?()[0] as! MusicArtwork
                if art.data != nil {
                    self.track.albumArt = art.data!
                } else {
                    if count > 20 { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        waitForData()
                    }
                }
                count += 1
            }
            waitForData()
            
            // Seeker
            self.trackDuration = Double(appleMusicApp?.currentTrack?.duration ?? 0)
            
        }
        
        // Post notification to update the menu bar track title
        updateMenuBarText()
        
    }
    
    private func updateMenuBarText() {
        DispatchQueue.main.async { [weak self] in
            guard let title = self?.track.title, let artist = self?.track.artist, let isPlaying = self?.isPlaying else { return }
            let trackInfo: [String: Any] = ["title": title, "artist": artist, "isPlaying": isPlaying]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TrackChanged"), object: nil, userInfo: trackInfo)
        }
    }
    
    func togglePlayPause() {
        switch connectedApp {
        case .spotify:
            spotifyApp?.playpause?()
        case .appleMusic:
            appleMusicApp?.playpause?()
        }
    }
    
    func previousTrack() {
        DispatchQueue.global(qos: .background).async {
            switch self.connectedApp {
            case .spotify:
                self.spotifyApp?.previousTrack?()
            case .appleMusic:
                self.appleMusicApp?.backTrack?()
            }
        }
    }
    
    func nextTrack() {
        DispatchQueue.global(qos: .background).async {
            switch self.connectedApp {
            case .spotify:
                self.spotifyApp?.nextTrack?()
            case .appleMusic:
                self.appleMusicApp?.nextTrack?()
            }
        }
    }
    
    func toggleLoveTrack() {
        switch connectedApp {
        case .appleMusic:
            if let isLovedTrack = appleMusicApp?.currentTrack?.loved {
                appleMusicApp?.currentTrack?.setLoved?(!isLovedTrack)
                self.isLoved = !isLovedTrack
            }
        case .spotify:
            print("Not supported")
        }
    }
    
    // MARK: - Seeker
    
    func getCurrentSeekerPosition() {
        guard isRunning else { return }
        self.seekerPosition = connectedApp == .spotify
        ? Double(spotifyApp?.playerPosition ?? 0)
        : Double(appleMusicApp?.playerPosition ?? 0)
    }
    
    func seekTrack() {
        spotifyApp?.setPlayerPosition?(seekerPosition)
    }
    
    func startTimer() {
        timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    }
    
    func pauseTimer() {
        timer.upstream.connect().cancel()
    }
    
    @objc private func popoverIsOpening(_ notification: NSNotification) {
        startTimer()
        popoverIsShown = true
    }
    
    @objc private func popoverIsClosing(_ notification: NSNotification) {
        pauseTimer()
        popoverIsShown = false
    }
    
}

enum ConnectedApps: String, Equatable, CaseIterable {
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

struct Track {
    var title = ""
    var artist = ""
    var album = ""
    var loved = false
    var albumArt = NSImage()
}

enum Constants {
    
    enum AppInfo {
        static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        static let repo = URL(string: "https://github.com/Jaysce/Jukebox")!
        static let website = URL(string: "https://jaysce.dev/projects/jukebox")!
    }
    
    enum StatusBar {
        static let marqueeFont = NSFont.systemFont(ofSize: 13, weight: .medium)
        static let barAnimationWidth: CGFloat = 14
        static let statusBarButtonLimit: CGFloat = 200
        static let statusBarButtonPadding: CGFloat = 8
    }
    
    enum Spotify {
        static let name = "Spotify"
        static let bundleID = "com.spotify.client"
        static let notification = "\(bundleID).PlaybackStateChanged"
    }
    
    enum AppleMusic {
        static let name = "Apple Music"
        static let bundleID = "com.apple.Music"
        static let notification = "\(bundleID).playerInfo"
    }
    
}
