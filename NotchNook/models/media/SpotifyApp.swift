//
//  SpotifyApp.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//

import SwiftUI

import SwiftUI
import ScriptingBridge

@Observable
final class SpotifyApp: BlankMediaApp<SpotifyApplication> {
    
    init() { super.init(meta: .spotify) }
    
    override func updateIsPlaying() { self.isPlaying = app?.playerState == .playing }
    
    override func updateTrack() {
        print("Trying to update track...")
        
        var currentTrack: (any SpotifyTrack)?
        currentTrack = self.app?.currentTrack
        let title = currentTrack?.name ?? Track.empty.title
        let artist = currentTrack?.artist ?? Track.empty.artist
        let album = currentTrack?.album ?? Track.empty.album
        
        print("New track detected: title")
        
        guard self.track.title != title &&
                self.track.artist != artist &&
                self.track.album != album else { return }
        
        var newTrack = Track()
        newTrack.title = title
        newTrack.artist = artist
        newTrack.album = album
        
        print("wryyyyyyy")
        
        Task(priority: .utility) { [currentTrack] in
            if let artworkURLString = currentTrack?.artworkUrl,
               let url = URL(string: artworkURLString) {
                URLSession.shared.dataTask(with: url) { data, response, error in
                    guard let data = data, error == nil else {
                        print(error!.localizedDescription)
                        return
                    }
                    Task {
                        await MainActor.run {
                            print("ploing")
                            self.track.albumArt = NSImage(data: data) ?? NSImage()
                        }
                    }
                }.resume()
            }
        }
        print("pipoca 1")
        self.track = newTrack
        print("pipoca 2")
    }
    
    override func toggleIsPlaying() { doSafeCrossBridgeAction { app?.playpause?() } }
    
    override func prevTrack() { doSafeCrossBridgeAction { app?.previousTrack?() } }
    
    override func nextTrack() { doSafeCrossBridgeAction { app?.nextTrack?() } }
        
    override func toggleLovedInTrack() { }
    
}
