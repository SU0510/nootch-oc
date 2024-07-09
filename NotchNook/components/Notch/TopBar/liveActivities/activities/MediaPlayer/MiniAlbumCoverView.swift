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
    
    var quickPeeks: [NotchNook.QuickPeek]? {
        if let player = MediaPlayer.shared.app {
            let newQuickPeeks: [NotchNook.QuickPeek] = [
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
                VStack {
                    AlbumCoverView(artwork: altImg ?? player.track.albumArt, cornerRadius: albumCornerRadius)
                        .padding(EdgeInsets(top: 6, leading: 6, bottom: 5, trailing: 6))
                        .matchedGeometryEffect(id: MiniAlbumCoverView.transitionID, in: ns)
                }
                .quickPeekScaling(scaling: notchNook.quickPeeks != nil)
                .animation(.bouncySmooth, value: [player.track.title, player.track.album, player.track.artist])
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
