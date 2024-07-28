//
//  AudioWavesView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct AudioWavesView: View {
    var altIsPlaying: Bool?
    
    @State private var hovering = false
    @Environment(\.mediaLiveActivitySettings) private var prefs
    
    var body: some View {
        let player = MediaControls.shared
        let isPlaying = altIsPlaying ?? player.isPlaying
        let volume = VolumeMonitor.shared.volume
        let albumAverageColor = player.track.albumArtAverageColor.lighter(by: 0.25) ?? .white
        let color: Color = prefs.coloredSpectograph ? Color(nsColor: albumAverageColor) : .white
        Button {
            player.togglePlayPause()
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
        .animation(.smooth, value: albumAverageColor)
    }
}

