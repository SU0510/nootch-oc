//
//  MediaPlayerView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI

struct MediaPlayerView: View, Equatable {
    static func == (lhs: MediaPlayerView, rhs: MediaPlayerView) -> Bool {
        lhs.track == rhs.track
    }
    
    var track: Track
    @Environment(\.namespace) private var ns
    @Environment(\.preventNextFocusFrontmostWindow) private var preventNextFocusFrontmostWindow
    
    var body: some View {
        HStack(spacing: 12) {
            AlbumCoverView(id: track.albumId, artwork: track.albumArt, cornerRadius: 28)
                .matchedGeometryEffect(id: MiniAlbumCoverView.transitionID, in: ns)
                .overlay(alignment: .bottomTrailing) {
                    if track.mediaApp.icon.isValid {
                        Button {
                            preventNextFocusFrontmostWindow()
                            track.mediaApp.openApp()
                        } label: {
                            Image(nsImage: track.mediaApp.icon)
                                .resizable()
                                .scaledToFit()
                                .shadow(color: .black.opacity(0.33), radius: 8, y: 0)
                                .shadow(color: .black.opacity(1), radius: 12, y: 3)
                                .frame(32)
                                .offset(x: 6, y: 6)
                        }
                        .buttonStyle(ShrinkOnClick(minSize: 0.9))
                    }
                }
            
            VStack(alignment: .leading, spacing: 2) {
                VStack(alignment: .leading, spacing: 2) {
                    Group {
                        Text(track.title)
                            .id(track.title)
                            .font(.system(size: 14, weight: .semibold))
                            .truncationMode(.tail)
                            .lineLimit(2)
                            .truncationMode(.tail)
                        
                        if !track.album.isEmpty {
                            Text(track.album)
                                .id(track.album)
                                .lineLimit(1)
                                .font(.system(size: 12, weight: .semibold))
                                .opacity(0.65)
                                .lineLimit(2)
                                .truncationMode(.tail)
                        }
                        
                        if !track.artist.isEmpty {
                            Text(track.artist)
                                .lineLimit(1)
                                .id(track.artist)
                                .font(.system(size: 11, weight: .medium))
                                .opacity(0.5)
                        }
                    }
                    .transition(.scaleAndBlur)
                }
                .allowsHitTesting(false)
                
                MediaControlsView()
                    .offset(x: -4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
        }
        .animation(.bouncySmooth, value: track.id)
        .foregroundStyle(.nonShockingWhite)
    }
}
