//
//  MockTopBar.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI
import Defaults

struct MockTopBar: View {
    var liveActivities: Set<LiveActivity>
    @Default(.mediaLiveActivitySettings) private var mediaLiveActivitySettings
    var body: some View {
        let la = liveActivities
        let liveActionWidth = TopBarView.liveActionWidth
        HStack(spacing: 0) {
            
            Group {
                if !la.isEmpty {
                    HStack {
                        if la.contains(.media) {
                            AlbumCoverView(id: "sample-album", artwork: .loCafeAvatar, cornerRadius: mediaLiveActivitySettings.albumCornerRadius).padding(.all, 6)
                        } else if la.contains(.shelf) {
                            ShelfIconView()
                        }
                    }
                    .frame(width: liveActionWidth)
                }
            }
            .transition(.scaleAndBlur(anchor: .topTrailing))
            
            TopBarSpacerView(height: TopBarView.height)
            
            Group {
                if !la.isEmpty {
                    HStack {
                        if la.contains(.shelf) {
                            ShelfFilesCountView()
                        } else if la.contains(.media) {
                            AudioWavesView(
                                altImg: .loCafeAvatar,
                                altIsPlaying: true,
                                prefs: mediaLiveActivitySettings
                            )
                        }
                    }
                    .frame(width: liveActionWidth)
                }
            }
            .transition(.scaleAndBlur(anchor: .topTrailing))
            
        }
        .frame(height: TopBarView.height)
    }
}
