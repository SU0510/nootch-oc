//
//  MediaPlayer.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI
import AVFoundation
import MediaPlayer

struct Media: Identifiable {
    var id = UUID()
    var albumCover: String // URL or name of the image resource
    var title: String
    var artist: String
}

@Observable
class MediaPlayer {
    var isPlaying: Bool = false
    var currentMedia: Media = Media(albumCover: "album_cover", title: "Song Title", artist: "Artist Name")
    
    private var player: AVAudioPlayer?
    
    init() {
        setupNowPlayingInfoCenter()
        loadMedia() // Load initial media
    }
    
    func setupNowPlayingInfoCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextTrack()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousTrack()
            return .success
        }
    }
    
    func loadMedia() {
        // Replace with actual media loading logic
        currentMedia = Media(albumCover: "new_album_cover", title: "New Song Title", artist: "New Artist Name")
        updateNowPlayingInfo()
    }
    
    func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentMedia.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentMedia.artist
        
        if let albumCoverImage = NSImage(named: currentMedia.albumCover) {
            let artwork = MPMediaItemArtwork(boundsSize: albumCoverImage.size) { size in
                return albumCoverImage
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func play() {
        isPlaying = true
        // Add your logic to start playback
        updateNowPlayingInfo()
    }
    
    func pause() {
        isPlaying = false
        // Add your logic to pause playback
        updateNowPlayingInfo()
    }
    
    func nextTrack() {
        // Add your logic to skip to the next track
        loadMedia()
    }
    
    func previousTrack() {
        // Add your logic to skip to the previous track
        loadMedia()
    }
}
