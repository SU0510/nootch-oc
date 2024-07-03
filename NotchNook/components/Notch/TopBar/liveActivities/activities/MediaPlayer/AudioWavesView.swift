//
//  AudioWavesView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct AudioWavesView: View {
    var altImg: NSImage?
    var altIsPlaying: Bool?
    var prefs: MediaLiveActivitySettings
    @State private var hovering = false
    var body: some View {
        if let player = MediaPlayer.shared.app {
            let isPlaying = altIsPlaying ?? MediaPlayer.shared.app?.isPlaying ?? false
            let volume = VolumeMonitor.shared.volume
            let albumArt = altImg ?? player.track.albumArt
            let albumAverageColor = albumArt.averageColor?.lighter(by: 0.25) ?? .white
            let color: Color = prefs.coloredSpectograph && albumArt.isValid ? Color(nsColor: albumAverageColor) : .white
            Button {
                MediaPlayer.shared.app?.toggleIsPlaying()
            } label: {
                ZStack {
                    AudioSpectrographRepresentable(playing: isPlaying, volume: volume, color: color)
                        .blur(radius: hovering ? 1.25 : 0)
//                        .opacity(hovering ? 0.75 : 1)
                    if hovering {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12))
                            .opacity(0.9)
                            .contentTransition(.symbolEffect)
                            .transition(.scaleAndBlur)
                    }
                }
                .background(.black.opacity(0.001))
                .contentShape(Rectangle())
                .onHover { newHovering in
                    withAnimation(.smooth(duration: 0.25)) {
                        hovering = newHovering
                    }
                }
            }
            .buttonStyle(ShrinkOnClick())
            .padding(.leading, 1)
            .frame(maxWidth: .infinity)
            .animation(.smooth, value: albumArt)
        }
    }
}

