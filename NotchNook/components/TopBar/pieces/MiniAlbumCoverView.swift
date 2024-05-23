//
//  MiniAlbumCoverView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct MiniAlbumCoverView: View {
    static let transitionID = "album-cover"
    @ObservedObject private var player = MediaPlayer.shared
    var ns: Namespace.ID
    var body: some View {
        VStack {
            AlbumCoverView(artwork: player.track.albumArt, cornerRadius: 5).padding(.all, 6)
                .matchedGeometryEffect(id: MiniAlbumCoverView.transitionID, in: ns)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .animation(.smooth(extraBounce: 0.15), value: [player.track.title, player.track.album, player.track.artist])
    }
}
