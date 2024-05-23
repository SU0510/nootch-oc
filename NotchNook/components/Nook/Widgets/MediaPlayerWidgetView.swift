//
//  MediaPlayerWidgetView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI
import MusicKit

struct MediaPlayerWidgetView: View {
    @ObservedObject private var player = MediaPlayer.shared    
    var ns: Namespace.ID
    var body: some View {
        HStack(spacing: 12) {
            AlbumCoverView(artwork: player.track.albumArt, cornerRadius: 28)
                .matchedGeometryEffect(id: MiniAlbumCoverView.transitionID, in: ns)
            VStack(alignment: .leading, spacing: 2) {
                VStack(alignment: .leading, spacing: 2) {
                    Group {
                        Text(player.track.title)
                            .id(player.track.title)
                            .font(.system(size: 14, weight: .semibold))
                            .truncationMode(.tail)
                            .lineLimit(2)
                            .truncationMode(.tail)
                        
                        Text(player.track.album)
                            .id(player.track.album)
                            .lineLimit(1)
                            .font(.system(size: 12, weight: .semibold))
                            .opacity(0.65)
                            .lineLimit(2)
                            .truncationMode(.tail)
                        
                        Text(player.track.artist)
                            .lineLimit(1)
                            .id(player.track.artist)
                            .font(.system(size: 11, weight: .medium))
                            .opacity(0.5)
                    }
                    .transition(.scaleAndBlur)
                }
                
                MediaControlsView(
                    isPlaying: player.isPlaying,
                    playPauseToggleFn: player.togglePlayPause,
                    previousFn: player.previousTrack,
                    forwardFn: player.nextTrack
                )
            }
        }
        .animation(.smooth(extraBounce: 0.15), value: [player.track.title, player.track.album, player.track.artist])
        .frame(minWidth: 225, maxWidth: 225, maxHeight: .infinity, alignment: .leading)
        .foregroundStyle(.white)
    }
}
