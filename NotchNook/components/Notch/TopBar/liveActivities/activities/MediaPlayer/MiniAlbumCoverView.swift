//
//  MiniAlbumCoverView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct MiniAlbumCoverView: View {
    static let transitionID = "album-cover"
    
    var altImg: NSImage?
    var enableQuickPeek = true
    var albumCornerRadius: Double
    
    @Environment(\.namespace) private var ns
    @Environment(\.notchNook) private var notchNook
        
    var quickPeeks: [NotchNookState.QuickPeek]? {
        if let player = MediaPlayer.shared.app {
            let newQuickPeeks: [NotchNookState.QuickPeek] = [
                .init(icon: "music.note", text: player.track.title),
                .init(icon: "music.mic", text: player.track.artist)
            ]
            return newQuickPeeks
        }
        return nil
    }
    
    var body: some View {
        Group {
            if let player = MediaPlayer.shared.app {
                let songId = player.track.title + player.track.album + player.track.artist
                VStack {
                    AlbumCoverView(id: songId, artwork: altImg ?? player.track.albumArt, cornerRadius: albumCornerRadius)
                        .id(songId)
                        .padding(6)
                        .matchedGeometryEffect(id: MiniAlbumCoverView.transitionID, in: ns)
                }
                .quickPeekScaling(scaling: notchNook.quickPeeks != nil)
                .animation(.bouncySmooth, value: songId)
                .onHover { hovering in
                    if enableQuickPeek, let quickPeeks {
                        notchNook.quickPeeks = hovering ? quickPeeks : nil
                    }
                }
                .onChange(of: player.track.title) { old, new in
                    if notchNook.quickPeeks != nil, let quickPeeks {
                        notchNook.quickPeeks = quickPeeks
                    }
                }
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}
