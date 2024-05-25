//
//  ContentViewModel.swift
//  Jukebox
//
//  Created by Sasindu Jayasinghe on 13/10/21.
//

import Foundation
import SwiftUI
import ScriptingBridge
import Combine

@Observable
class MediaPlayer {
    static let shared = MediaPlayer()
    
    var connectedApp: MediaAppMeta? = nil
    var installedApps = Set<MediaAppMeta>()
    var spotifyApp: SpotifyApp?
    var appleMusicApp: AppleMusicApp?

    // Seeker
//    var timer: Publishers.Autoconnect<Timer.TimerPublisher>?
//    var trackDuration: Double = 0
//    var seekerPosition: Double = 0
    
    var app: MediaApp? {
        if connectedApp == .appleMusic, let appleMusicApp {
            return appleMusicApp
        } else if connectedApp == .spotify, let spotifyApp {
            return spotifyApp
        }
        return nil
    }
        
    init() { setupMusicApps() }
    
    // MARK: - Setup
    
    private func detectInstalledApps() {
        if isAppInstalled(MediaAppMeta.spotify.bundleID) { installedApps.insert(.spotify) }
        if isAppInstalled(MediaAppMeta.appleMusic.bundleID) { installedApps.insert(.appleMusic) }
    }
    
    private func setupMusicApps() {
        detectInstalledApps()
        
        if spotifyApp == nil && installedApps.contains(.spotify) {
            spotifyApp = SpotifyApp()
        }
        
        if appleMusicApp == nil && installedApps.contains(.appleMusic)  {
            appleMusicApp = AppleMusicApp()
        }
    }
    
    // MARK: - Seeker
    
//    func getCurrentSeekerPosition() {
//        guard isRunning else { return }
//        self.seekerPosition = connectedApp == .spotify
//        ? Double(spotifyApp?.playerPosition ?? 0)
//        : Double(appleMusicApp?.playerPosition ?? 0)
//    }
//    
//    func seekTrack() {
//        spotifyApp?.setPlayerPosition?(seekerPosition)
//    }
//    
//    func startTimer() {
//        timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
//    }
//    
//    func pauseTimer() {
//        timer?.upstream.connect().cancel()
//        timer = nil
//    }
    
}


