//
//  MediaPlayerWidgetView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI
import MusicKit

struct MediaPlayerWidgetView: View {
    var ns: Namespace.ID
    var body: some View {
        
        if let track = MediaPlayer.shared.app?.track {
        HStack(spacing: 12) {
                AlbumCoverView(artwork: track.albumArt, cornerRadius: 28)
                    .matchedGeometryEffect(id: MiniAlbumCoverView.transitionID, in: ns)
                VStack(alignment: .leading, spacing: 2) {
                    VStack(alignment: .leading, spacing: 2) {
                        Group {
                            Text(track.title)
                                .id(track.title)
                                .font(.system(size: 14, weight: .semibold))
                                .truncationMode(.tail)
                                .lineLimit(2)
                                .truncationMode(.tail)
                            
                            Text(track.album)
                                .id(track.album)
                                .lineLimit(1)
                                .font(.system(size: 12, weight: .semibold))
                                .opacity(0.65)
                                .lineLimit(2)
                                .truncationMode(.tail)
                            
                            Text(track.artist)
                                .lineLimit(1)
                                .id(track.artist)
                                .font(.system(size: 11, weight: .medium))
                                .opacity(0.5)
                        }
                        .transition(.scaleAndBlur)
                    }
                    .allowsHitTesting(false)
                    
                    if let app = MediaPlayer.shared.app {
                        MediaControlsView(
                            isPlaying: app.isPlaying,
                            playPauseToggleFn: app.toggleIsPlaying,
                            previousFn: app.prevTrack,
                            forwardFn: app.nextTrack
                        )
                    }
                }
        }
        .animation(.smooth(extraBounce: 0.15), value: [track.title, track.album, track.artist])
        .frame(minWidth: 225, maxWidth: 225, maxHeight: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        }
    }
}
