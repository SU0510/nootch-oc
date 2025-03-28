//
//  MiniPlayerView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct MiniPlayerView: View {    
    var body: some View {
        let track = MediaManager.shared.track
        HStack(spacing: 2) {
            AlbumCoverView(id: track.albumId, artwork: track.albumArt, cornerRadius: 8).padding(.all, 3)
            MediaControlsView()
        }
        .animation(.bouncySmooth, value: track.id)
    }
}
