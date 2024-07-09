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
            if let app = MediaPlayer.shared.app, app.isAppRunning {
                MediaPlayerView(track: app.track, appIcon: app.meta.icon)
            } else {
                NoMediaAppsView()
            }
        }
        .paddingDependingOnArrPos(arrayPosition: arrayPosition, padding: nookSettings.widgetsPadding)
    }
}
