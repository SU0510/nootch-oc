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
    
    @State private var hovering = false
    @Environment(\.mediaLiveActivitySettings) private var prefs
    
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
                    Group {
                        switch prefs.effect {
                            case .audioSpectrograph:
                                AudioSpectrographRepresentable(playing: isPlaying, volume: volume, color: color)
                                    .blur(radius: hovering ? 1.25 : 0)
                                
                            case .waves:
                                WaveViewRepresentable(volume: volume, color: color)
                                    .blur(radius: hovering ? 1.25 : 0)
                                    .fadeOnEdges(axis: .horizontal, topLeadingFadeLength: 8, bottomTrailingFadeLength: 12, curve: .easeIn)
                                
                            case .gif:
                                GIFView()
                                    .offset(y: prefs.gifOffset)
                        }
                    }
                    .transition(.scaleAndBlur)
                    
                    
                    if hovering {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12))
                            .opacity(0.9)
                            .contentTransition(.symbolEffect)
                            .transition(.scaleAndBlur)
                    }
                }
                .animation(.spring, value: prefs.effect)
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

