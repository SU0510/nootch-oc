//
//  MediaControlsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/05/24.
//

import SwiftUI

struct MediaControlsView: View {
    private var mediaControls = MediaControls.shared
    
    var body: some View {
        HStack(spacing: 0) {
            CircleButton(icon: "backward.end.fill", iconSize: 10, action: mediaControls.previousTrack)
            CircleButton(icon: mediaControls.isPlaying ? "pause.fill" : "play.fill", iconSize: 13, fade: false, action: mediaControls.togglePlayPause)
            CircleButton(icon: "forward.end.fill", iconSize: 10, action: mediaControls.nextTrack)
        }
    }
}
