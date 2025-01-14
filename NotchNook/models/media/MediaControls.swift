//
//  MediaApp.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//
// This uses private APIs to get better, low-level controls of all playing media on the device. https://github.com/theos/headers/blob/master/MediaRemote/MediaRemote.h

import SwiftUI
import Defaults

@Observable
class MediaControls {
    static let shared = MediaControls()
    
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
    
    private let bundle: CFBundle
    private let MRMediaRemoteGetNowPlayingInfo: MRMediaRemoteGetNowPlayingInfoFunction
    private let MRMediaRemoteRegisterForNowPlayingNotifications: MRMediaRemoteRegisterForNowPlayingNotificationsFunction
    private let MRMediaRemoteSendCommand: MRMediaRemoteSendCommandFunction
    private let MRMediaRemoteGetNowPlayingApplicationIsPlaying: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction
    private let MRMediaRemoteGetNowPlayingApplicationPlaybackState: MRMediaRemoteGetNowPlayingApplicationPlaybackStateFunction
    private let MRMediaRemoteGetNowPlayingApplicationPID: MRMediaRemoteGetNowPlayingApplicationPIDFunction
    
    private init() {
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")) else {
            fatalError("Failed to load MediaRemote.framework")
        }
        self.bundle = bundle
        
        guard let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString),
              let MRMediaRemoteRegisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString),
              let MRMediaRemoteSendCommandPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString),
              let MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString),
              let MRMediaRemoteGetNowPlayingApplicationPlaybackStatePointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationPlaybackState" as CFString),
              let MRMediaRemoteGetNowPlayingApplicationPIDPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationPID" as CFString) else {
            fatalError("Failed to get function pointers")
        }
        
        self.MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
        self.MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteRegisterForNowPlayingNotificationsPointer, to: MRMediaRemoteRegisterForNowPlayingNotificationsFunction.self)
        self.MRMediaRemoteSendCommand = unsafeBitCast(MRMediaRemoteSendCommandPointer, to: MRMediaRemoteSendCommandFunction.self)
        self.MRMediaRemoteGetNowPlayingApplicationIsPlaying = unsafeBitCast(MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer, to: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction.self)
        self.MRMediaRemoteGetNowPlayingApplicationPlaybackState = unsafeBitCast(MRMediaRemoteGetNowPlayingApplicationPlaybackStatePointer, to: MRMediaRemoteGetNowPlayingApplicationPlaybackStateFunction.self)
        self.MRMediaRemoteGetNowPlayingApplicationPID = unsafeBitCast(MRMediaRemoteGetNowPlayingApplicationPIDPointer, to: MRMediaRemoteGetNowPlayingApplicationPIDFunction.self)
        
        self.monitorMediaRemoteNotifications()
        self.updateMediaInfo()
    }
    
    private func monitorMediaRemoteNotifications() {
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
        
        let notificationNames = [
            "kMRMediaRemoteNowPlayingInfoDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationPlaybackStateDidChangeNotification"
        ]
        
        notificationNames.forEach { name in
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name(rawValue: name),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.updateMediaInfo()
            }
        }
    }
    
    private func isMediaActuallyPlaying(completion: @escaping (Bool) -> Void) {
        MRMediaRemoteGetNowPlayingApplicationPlaybackState(DispatchQueue.main) { playbackState in
            let isPlaying = playbackState == MRPlaybackState.playing.rawValue
            let isPaused = playbackState == MRPlaybackState.paused.rawValue
            completion(isPlaying || isPaused)
        }
    }
    
    private func updateMediaInfo() {
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] info in
            guard let self = self else { return }
            
            // Add delay before any state checks
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard let info = info as? [String: Any], !info.isEmpty else {
                    self.resetTrackState()
                    return
                }
                
                let newTrackInfo = self.extractTrackInfo(from: info)
                
                self.MRMediaRemoteGetNowPlayingApplicationPlaybackState(DispatchQueue.main) { playbackState in
                    if playbackState == MRPlaybackState.stopped.rawValue {
                        // Double-check playback state after another brief delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.MRMediaRemoteGetNowPlayingApplicationPlaybackState(DispatchQueue.main) { finalPlaybackState in
                                if finalPlaybackState == MRPlaybackState.stopped.rawValue {
                                    self.resetTrackState()
                                    return
                                }
                                
                                if self.isCurrentTrack(newTrackInfo) {
                                    self.updatePlaybackState()
                                } else {
                                    self.handleTrackChange(info: info, trackInfo: newTrackInfo)
                                }
                            }
                        }
                        return
                    }
                    
                    if self.isCurrentTrack(newTrackInfo) {
                        self.updatePlaybackState()
                    } else {
                        self.handleTrackChange(info: info, trackInfo: newTrackInfo)
                    }
                }
            }
        }
    }
    
    private func extractTrackInfo(from info: [String: Any]) -> (title: String, artist: String, album: String) {
        let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
        let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
        let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
        return (title, artist, album)
    }
    
    private func isCurrentTrack(_ trackInfo: (title: String, artist: String, album: String)) -> Bool {
        track.title == trackInfo.title &&
        track.artist == trackInfo.artist &&
        track.album == trackInfo.album
    }
    
    private func handleTrackChange(info: [String: Any], trackInfo: (title: String, artist: String, album: String)) {
        isMediaActuallyPlaying { [weak self] isActiveOrPaused in
            guard let self = self, isActiveOrPaused else {
                self?.resetTrackState()
                return
            }
            
            let newTrack = self.createTrack(from: trackInfo, info: info)
            self.updateTrackWithAppInfo(newTrack)
        }
    }
    
    private func createTrack(from trackInfo: (title: String, artist: String, album: String), info: [String: Any]) -> Track {
        var newTrack = Track()
        newTrack.title = trackInfo.title
        newTrack.artist = trackInfo.artist
        newTrack.album = trackInfo.album
        newTrack.albumArt = extractAlbumArt(from: info)
        return newTrack
    }
    
    private func extractAlbumArt(from info: [String: Any]) -> NSImage {
        if let artworkData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
            return NSImage(data: artworkData) ?? NSImage()
        }
        if let artwork = info["kMRMediaRemoteNowPlayingInfoArtwork"] as? NSImage {
            return artwork
        }
        if let artwork = info["MPMediaItemPropertyArtwork"] as? NSImage {
            return artwork
        }
        return NSImage()
    }
    
    private func updateTrackWithAppInfo(_ newTrack: Track) {
        MRMediaRemoteGetNowPlayingApplicationPID(DispatchQueue.main) { [weak self] pid in
            guard let self = self else { return }
            
            let systemAppMeta = SystemAppMeta(pid: pid)
            if systemAppMeta.name == "NotchNook" { return }
            
            self.validateAndUpdateTrack(newTrack, systemAppMeta)
        }
    }
    
    private func validateAndUpdateTrack(_ newTrack: Track, _ systemAppMeta: SystemAppMeta) {
        MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.main) { [weak self] isActuallyPlaying in
            guard let self = self else { return }
            
            if !isActuallyPlaying {
                self.resetTrackState()
                return
            }
            
            var updatedTrack = newTrack
            updatedTrack.mediaApp = systemAppMeta
            
            if self.track.isValidReplacement(updatedTrack) {
                self.setNewTrackWithDelay(updatedTrack)
            }
        }
    }
    
    private func setNewTrackWithDelay(_ newTrack: Track) {
        TimersManager.shared.addTimer("set-new-track", delay: 0.05) { [weak self] _ in
            guard let self = self else { return }
            
            if self.track.isValidReplacement(newTrack) {
                DispatchQueue.main.async {
                    self.track = newTrack
                    self.updatePlaybackState()
                }
            }
        }
    }
    
    private func resetTrackState() {
        DispatchQueue.main.async { [weak self] in
            self?.track = .empty
            self?.isPlaying = false
        }
    }
    
    private func updatePlaybackState() {
        MRMediaRemoteGetNowPlayingApplicationPlaybackState(DispatchQueue.main) { [weak self] playbackState in
            guard let self = self else { return }
            self.isPlaying = playbackState == MRPlaybackState.playing.rawValue
            
            if playbackState == MRPlaybackState.stopped.rawValue {
                self.track = .empty
            }
            
            self.updateLiveActivities()
        }
    }
    
    func togglePlayPause() {
        let success = MRMediaRemoteSendCommand(MRCommand.togglePlayPause.rawValue, nil)
        if !success { print("Media control failed: Toggle play/pause") }
    }
    
    func goToPreviousTrack() {
        let success = MRMediaRemoteSendCommand(MRCommand.previousTrack.rawValue, nil)
        if !success { print("Media control failed: Previous track") }
    }
    
    func goToNextTrack() {
        let success = MRMediaRemoteSendCommand(MRCommand.nextTrack.rawValue, nil)
        if !success { print("Media control failed: Next track") }
    }
    
    private func updateLiveActivities() {
        if track != .empty {
            if !isPlaying { return }
            ActiveLiveActivitiesManager.shared.activeLiveActivities.insert(.media)
        } else {
            ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.media)
        }
    }
}

// Helper types
private typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping (CFDictionary) -> Void) -> Void
private typealias MRMediaRemoteRegisterForNowPlayingNotificationsFunction = @convention(c) (DispatchQueue) -> Void
private typealias MRMediaRemoteSendCommandFunction = @convention(c) (UInt32, NSDictionary?) -> Bool
private typealias MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
private typealias MRMediaRemoteGetNowPlayingApplicationPlaybackStateFunction = @convention(c) (DispatchQueue, @escaping (UInt32) -> Void) -> Void
private typealias MRMediaRemoteGetNowPlayingApplicationPIDFunction = @convention(c) (DispatchQueue, @escaping (Int32) -> Void) -> Void

private enum MRCommand: UInt32 {
    case play = 0
    case pause = 1
    case togglePlayPause = 2
    case stop = 3
    case nextTrack = 4
    case previousTrack = 5
}

private enum MRPlaybackState: UInt32 {
    case unknown = 0
    case playing = 1
    case paused = 2
    case stopped = 3
    case interrupted = 4
}
