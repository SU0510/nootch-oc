//
//  MiniAlbumCoverView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct MiniAlbumCoverView: View, Equatable {
    static func == (lhs: MiniAlbumCoverView, rhs: MiniAlbumCoverView) -> Bool {
        lhs.enableQuickPeek == rhs.enableQuickPeek && lhs.albumCornerRadius == rhs.albumCornerRadius
    }
    
    static let transitionID = "album-cover"
    
    var enableQuickPeek = true
    var albumCornerRadius: Double
    
    @Environment(\.namespace) private var ns
    @Environment(\.notchNook) private var notchNook
    @Environment(\.preventNextFocusFrontmostWindow) private var preventNextFocusFrontmostWindow

    var quickPeeks: [NotchNookState.QuickPeek]? {
        [
            .init(icon: "music.note", text: MediaControls.shared.track.title),
            .init(icon: "music.mic", text: MediaControls.shared.track.artist)
        ]
    }
    
    var body: some View {
        let track = MediaControls.shared.track
        VStack {
            Button {
                preventNextFocusFrontmostWindow()
                track.mediaApp.openApp()
            } label: {
                AlbumCoverView(id: track.albumId, artwork: track.albumArt, cornerRadius: albumCornerRadius)
                    .padding(6)
                    .matchedGeometryEffect(id: MiniAlbumCoverView.transitionID, in: ns)
            }
            .buttonStyle(ShrinkOnClick())
        }
        .quickPeekScaling(scaling: notchNook.quickPeeks != nil)
        .animation(.bouncySmooth, value: track.id)
        .onHover { hovering in
            if enableQuickPeek {
                notchNook.quickPeeks = hovering ? quickPeeks : nil
            }
        }
        .onChange(of: track.title) { old, new in
            if notchNook.quickPeeks != nil {
                notchNook.quickPeeks = quickPeeks
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}
