//
//  AVLooperPlayer.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import Foundation
import SwiftUI
import AVKit

class AVLooperPlayer: AVQueuePlayer {
    private var looper: AVPlayerLooper!
    
    func togglePlaying() { if self.isPlaying { self.pause() } else { self.play() } }
    
    convenience override init(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        self.init(playerItem: playerItem)
        looper = AVPlayerLooper(player: self, templateItem: playerItem)

        if #available(macOS 12.0, *) {
            self.preventsDisplaySleepDuringVideoPlayback = false
        }
        self.appliesMediaSelectionCriteriaAutomatically = false
    }

}

extension AVPlayer {
    var isPlaying: Bool { self.timeControlStatus == AVPlayer.TimeControlStatus.playing }
}

struct VPlayer: NSViewRepresentable {
    var player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.player = player
        view.videoGravity = .resizeAspectFill
        
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
      nsView.player = player
    }
}
