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
    @Environment(\.mediaWidgetSettings) private var prefs
    
    var body: some View {
        VStack {
            let player = MediaManager.shared
            if player.track != .empty {
                MediaPlayerView(track: player.track)
            } else {
                NoMediaAppsView()
            }
        }
        .paddingDependingOnArrPos(arrayPosition: arrayPosition, padding: nookSettings.widgetsPadding)
        .frame(prefs.size.screenPtsCGSize, .leading)
    }
}
