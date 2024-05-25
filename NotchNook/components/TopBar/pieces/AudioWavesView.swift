//
//  AudioWavesView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct AudioWavesView: View {
    var body: some View {
        if let player = MediaPlayer.shared.app {
            let albumArt = player.track.albumArt
            let albumAverageColor = albumArt.averageColor?.lighter(by: 0.25) ?? .white
            let color: Color = albumArt.isValid ? Color(nsColor: albumAverageColor) : .white
            AudioSpectrograph(color: color)
                .padding(.leading, 1)
                .frame(maxWidth: .infinity)
                .animation(.smooth, value: albumArt)
        }
    }
}

