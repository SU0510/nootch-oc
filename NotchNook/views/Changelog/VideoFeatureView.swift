//
//  VideoFeatureView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import SwiftUI
import AVKit

struct VideoFeatureView: View {
    var player: AVPlayer
    var title: String
    var description: String

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            VPlayer(player: player)
                .frame(width: 250, height: 120)
                .contentShape(Rectangle())
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .allowsHitTesting(false)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.title2).fontWeight(.bold)
                Text(description).font(.system(size: 14, weight: .light)).opacity(0.75)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 320, alignment: .leading)
        }
        .onAppear { player.play() }
        .onDisappear { player.pause() }
    }
}
