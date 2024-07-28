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
    
    var isPlaying: Bool = false
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
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateMediaInfo()
        }
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePlaybackState()
        }
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "kMRMediaRemoteNowPlayingApplicationDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateMediaInfo()
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
            
            self.isMediaActuallyPlaying { isActiveOrPaused in
                if let info = info as? [String: Any], !info.isEmpty, isActiveOrPaused {
                    let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
                    let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
                    let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
                    
                    var newTrack = Track()
                    newTrack.title = title
                    newTrack.artist = artist
                    newTrack.album = album
                    
                    if let artworkData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
                        newTrack.albumArt = NSImage(data: artworkData) ?? NSImage()
                    } else if let artwork = info["kMRMediaRemoteNowPlayingInfoArtwork"] as? NSImage {
                        newTrack.albumArt = artwork
                    } else if let artwork = info["MPMediaItemPropertyArtwork"] as? NSImage {
                        newTrack.albumArt = artwork
                    }
                    
                    // Get the PID of the currently playing application
                    self.MRMediaRemoteGetNowPlayingApplicationPID(DispatchQueue.main) { pid in
                        newTrack.mediaApp = SystemAppMeta(pid: pid)
                        
                        if self.track.isValidReplacement(newTrack) {
                            print("preparing", newTrack)
                            TimersManager.shared.addTimer("set-new-track", delay: 0.5) { _ in
                                DispatchQueue.main.async {
                                    self.track = newTrack
                                    self.updatePlaybackState()
                                }
                            }
                        }
                    }
                } else if !isActiveOrPaused {
                    self.track = .empty
                    self.updatePlaybackState()
                }
            }
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
        MRMediaRemoteSendCommand(MRCommand.togglePlayPause.rawValue, nil)
    }
    
    func previousTrack() {
        MRMediaRemoteSendCommand(MRCommand.previousTrack.rawValue, nil)
    }
    
    func nextTrack() {
        MRMediaRemoteSendCommand(MRCommand.nextTrack.rawValue, nil)
    }
    
    private func updateLiveActivities() {
        if track != .empty {
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
