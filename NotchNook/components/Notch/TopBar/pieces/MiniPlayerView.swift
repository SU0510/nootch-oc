//
//  MiniPlayerView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct MiniPlayerView: View {    
    var body: some View {
        if let player = MediaPlayer.shared.app {
            HStack(spacing: 2) {
                AlbumCoverView(artwork: player.track.albumArt, cornerRadius: 8).padding(.all, 3)
                MediaControlsView(
                    isPlaying: player.isPlaying,
                    playPauseToggleFn: player.toggleIsPlaying,
                    previousFn: player.prevTrack,
                    forwardFn: player.nextTrack
                )
            }
            .animation(.bouncySmooth, value: [player.track.title, player.track.album, player.track.artist])
        }
    }
}
