//
//  MediaControlsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/05/24.
//

import SwiftUI

struct MediaControlsView: View {
    var isPlaying: Bool
    var playPauseToggleFn: () -> ()
    var previousFn: () -> ()
    var forwardFn: () -> ()
    var body: some View {
        HStack(spacing: 0) {
            CircleButton(icon: "backward.end.fill", iconSize: 10, action: previousFn)
            CircleButton(icon: isPlaying ? "pause.fill" : "play.fill", iconSize: 13, fade: false, action: playPauseToggleFn)
            CircleButton(icon: "forward.end.fill", iconSize: 10, action: forwardFn)
        }
    }
}
