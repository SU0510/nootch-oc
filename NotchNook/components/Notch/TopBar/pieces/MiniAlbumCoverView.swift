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
    var prefs: MediaLiveActivitySettings
    
    @Environment(\.namespace) private var ns
    
    var body: some View {
        if let player = MediaPlayer.shared.app {
            VStack {
                AlbumCoverView(artwork: altImg ?? player.track.albumArt, cornerRadius: prefs.albumCornerRadius).padding(.all, 6)
                    .matchedGeometryEffect(id: MiniAlbumCoverView.transitionID, in: ns)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .animation(.smooth(extraBounce: 0.15), value: [player.track.title, player.track.album, player.track.artist])
        }
    }
}
