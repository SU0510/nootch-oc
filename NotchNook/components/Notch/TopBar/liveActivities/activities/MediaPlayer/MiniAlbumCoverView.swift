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
    var laPrefs: LiveActivitiesSettings
    var prefs: MediaLiveActivitySettings
    
    @Environment(\.namespace) private var ns
    @Environment(\.notchNook) private var notchNook
    
    var quickPeeks: [NotchNook.QuickPeek]? {
        if let player = MediaPlayer.shared.app {
            var newQuickPeeks: [NotchNook.QuickPeek] = [
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
                    AlbumCoverView(artwork: altImg ?? player.track.albumArt, cornerRadius: prefs.albumCornerRadius)
                        .padding(6)
                        .matchedGeometryEffect(id: MiniAlbumCoverView.transitionID, in: ns)
                }
                .quickPeekScaling(scaling: notchNook.quickPeeks != nil)
                .animation(.smooth(extraBounce: 0.15), value: [player.track.title, player.track.album, player.track.artist])
                .onHover { hovering in
                    if laPrefs.enableQuickPeek, let quickPeeks {
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
