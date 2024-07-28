//
//  MediaPlayerWidgetView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI
import MusicKit
import Defaults

struct MediaPlayerWidgetView: View {
    var arrayPosition: ArrayPosition
    @Environment(\.nookSettings) private var nookSettings
    
    var body: some View {
        VStack {
            let player = MediaControls.shared
            if player.track != .empty {
                MediaPlayerView(track: player.track)
            } else {
                ////                NoMediaPlayingView()
            }
        }
        .paddingDependingOnArrPos(arrayPosition: arrayPosition, padding: nookSettings.widgetsPadding)
    }
}
