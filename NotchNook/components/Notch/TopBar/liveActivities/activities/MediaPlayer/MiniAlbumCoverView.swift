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
    
    var quickPeaks: [NotchNook.QuickPeak]? {
        if let player = MediaPlayer.shared.app {
            var newQuickPeaks: [NotchNook.QuickPeak] = [
                .init(icon: "music.note", text: player.track.title),
                .init(icon: "music.mic", text: player.track.artist)
            ]
            return newQuickPeaks
        }
        return nil
    }
    
    var body: some View {
        Group {
            if let player = MediaPlayer.shared.app {
                VStack {
                    AlbumCoverView(artwork: altImg ?? player.track.albumArt, cornerRadius: prefs.albumCornerRadius).padding(.all, 6)
                        .matchedGeometryEffect(id: MiniAlbumCoverView.transitionID, in: ns)
                }
                .scaleEffect(NotchNook.shared.quickPeaks == nil ? 1 : 1.2, anchor: .topLeading)
                .animation(.smooth(extraBounce: 0.15), value: [player.track.title, player.track.album, player.track.artist])
                .onHover { hovering in
                    if laPrefs.enableQuickPeak, let quickPeaks {
                        NotchNook.shared.quickPeaks = hovering ? quickPeaks : nil
                    }
                }
                .onChange(of: player.track.title) { old, new in
                    if NotchNook.shared.quickPeaks != nil, let quickPeaks {
                        NotchNook.shared.quickPeaks = quickPeaks
                    }
                }
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}
