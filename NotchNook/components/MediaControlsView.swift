//
//  MediaControlsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/05/24.
//

import SwiftUI

struct MediaControlsView: View {
    private var mediaControls = MediaManager.shared
    
    var body: some View {
        HStack(spacing: 0) {
            if mediaControls.isLikelyBrowserApp() {
                CircleButton(icon: mediaControls.isPlaying ? "pause.fill" : "play.fill", iconSize: 15, fade: false) {
                    mediaControls.togglePlayPause()
                }
                
                CircleButton(icon: "x.circle", iconSize: 15, fade: false) {
                    mediaControls.resetData()
                }
            } else {
                TrackButtonView(direction: .previous, iconSize: 10)
                CircleButton(icon: mediaControls.isPlaying ? "pause.fill" : "play.fill", iconSize: 15, fade: false, action: mediaControls.togglePlayPause)
                TrackButtonView(direction: .next, iconSize: 10)
            }
        }
    }
}
