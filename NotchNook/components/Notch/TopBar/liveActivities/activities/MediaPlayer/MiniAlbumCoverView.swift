//
//  MiniAlbumCoverView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI
import Defaults

struct MiniAlbumCoverView: View, Equatable {
    static func == (lhs: MiniAlbumCoverView, rhs: MiniAlbumCoverView) -> Bool {
        lhs.enableQuickPeek == rhs.enableQuickPeek && lhs.quickPeekEvent == rhs.quickPeekEvent && lhs.albumCornerRadius == rhs.albumCornerRadius
    }
    
    static let transitionID = "album-cover"
    
    var enableQuickPeek = true
    var quickPeekEvent = false
    var albumCornerRadius: Double
    
    @Environment(\.namespace) private var ns
    @Environment(\.notchNook) private var notchNook
    @Environment(\.preventNextFocusFrontmostWindow) private var preventNextFocusFrontmostWindow
    
    @State private var quickPeekTimer: Timer?
    
    var quickPeeks: [NotchNookState.QuickPeek]? {
        [
            .init(icon: "music.note", text: MediaManager.shared.track.title),
            .init(icon: "music.mic", text: MediaManager.shared.track.artist)
        ]
    }
    
    var body: some View {
        let track = MediaManager.shared.track
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
        .quickPeekScaling(scaling: notchNook.quickPeeks?.first?.anchor == .topLeading)
        .animation(.bouncySmooth, value: track.id)
        .onHover { hovering in
            if enableQuickPeek, hovering {
                notchNook.quickPeeks = quickPeeks
            } else if !hovering {
                notchNook.quickPeeks = nil
            }
        }
        .onChange(of: track.title) { old, new in
            if notchNook.quickPeeks == nil, quickPeekEvent, track != .empty {
                quickPeekTimer?.invalidate()
                
                notchNook.quickPeeks = quickPeeks
                
                quickPeekTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
                    notchNook.quickPeeks = nil
                }
            } else if notchNook.quickPeeks != nil {
                notchNook.quickPeeks = quickPeeks
            }
        }
        .onDisappear {
            notchNook.quickPeeks = nil
            quickPeekTimer?.invalidate()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}
