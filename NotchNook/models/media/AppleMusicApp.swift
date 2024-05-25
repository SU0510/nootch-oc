//
//  AppleMusicApp.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//

import SwiftUI
import ScriptingBridge

@Observable
final class AppleMusicApp: BlankMediaApp<MusicApplication> {
    
    init() { super.init(meta: .appleMusic) }
        
    override func updateIsPlaying() {
        self.isPlaying = app?.playerState == .playing
    }
    
    override func updateTrack() {
        let currentTrack = self.app?.currentTrack
        let title = currentTrack?.name ?? Track.empty.title
        let artist = currentTrack?.artist ?? Track.empty.artist
        let album = currentTrack?.album ?? Track.empty.album
        
        guard self.track.title != title &&
                self.track.artist != artist &&
                self.track.album != album else {
            self.track.loved = self.track.loved
            return
        }
        
        var newTrack = Track()
        newTrack.title = title
        newTrack.artist = artist
        newTrack.album = album
        newTrack.loved = currentTrack?.loved
        
        Task(priority: .utility) { [currentTrack] in
            var count = 0
            var waitForData: (() async ->())!
            waitForData = {
                if let art = currentTrack?.artworks?()[0] as? MusicArtwork, art.data != nil {
                    await MainActor.run {
                        self.track.albumArt = art.data!
                    }
                } else {
                    if count > 20 { return }
                    await wait(0.25)
                    await waitForData()
                }
                count += 1
            }
            await waitForData()
        }
        
        DispatchQueue.main.async { self.track = newTrack }
    }
    
    override func toggleIsPlaying() { app?.playpause?() }
    
    override func prevTrack() { app?.backTrack?() }
    
    override func nextTrack() { app?.nextTrack?() }
        
    override func toggleLovedInTrack() {
        if let oldLoved = self.track.loved {
            self.track.loved?.toggle()
            app?.currentTrack?.setLoved?(!oldLoved)
        }
    }
}
