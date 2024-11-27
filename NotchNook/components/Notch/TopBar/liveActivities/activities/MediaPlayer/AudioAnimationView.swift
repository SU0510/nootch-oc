//
//  AudioAnimationView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct AudioAnimationView: View {
    
    var altIsPlaying: Bool?
    
    @State private var isHovering = false
    @Environment(\.mediaLiveActivitySettings) private var userPrefs
    
    var body: some View {
        let player = MediaControls.shared
        let isPlaying = altIsPlaying ?? player.isPlaying
        let volume = VolumeMonitor.shared.volume
        let albumAverageColor = player.track.albumArtAverageColor.lighter(by: 0.25) ?? .nonShockingWhite
        let color: Color = userPrefs.isAutomaticallyColored ? Color(nsColor: albumAverageColor) : .nonShockingWhite

        Button {
            player.togglePlayPause()
        } label: {
            ZStack {
                Group {
                    switch userPrefs.effect {
                        case .audioSpectrograph:
                            AudioSpectrographView(isPlaying: isPlaying, volume: volume, color: color)
                                .blur(radius: isHovering ? 1.25 : 0)
                            
                        case .waves:
                            WaveView(volume: volume, color: color, isPlaying: isPlaying)
                                .blur(radius: isHovering ? 1.25 : 0)
                                .fadeOnEdges(axis: .horizontal, topLeadingFadeLength: 8, bottomTrailingFadeLength: 12, curve: .easeIn)
                            
                        case .gif:
                            GIFView()
                                .offset(y: userPrefs.gifOffset)
                            
                        case .vibratingCircle:
                            VibratingCircleView(color: color, isPlaying: isPlaying)
                                .padding(2)
                    }

                }
                .transition(.scaleAndBlur)
                
                if isHovering {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 12))
                        .opacity(0.9)
                        .contentTransition(.symbolEffect)
                        .transition(.scaleAndBlur)
                }
            }
            .animation(.spring, value: userPrefs.effect)
            .background(.black.opacity(0.001))
            .contentShape(Rectangle())
            .onHover { newIsHovering in
                withAnimation(.smooth(duration: 0.25)) {
                    isHovering = newIsHovering
                }
            }
        }
        .buttonStyle(ShrinkOnClick())
        .padding(.leading, 1)
        .frame(maxWidth: .infinity)
        .animation(.smooth, value: albumAverageColor)
    }
}
