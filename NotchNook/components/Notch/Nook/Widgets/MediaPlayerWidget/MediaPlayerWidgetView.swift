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
    @Default(.nookSettings) private var nookSettings
    var body: some View {
        VStack {
            if let app = MediaPlayer.shared.app, app.isAppRunning {
                MediaPlayerView(track: app.track, appIcon: app.meta.icon)
            } else {
                NoMediaAppsView()
            }
        }
        .padding(EdgeInsets(
            top: 0,
            leading: arrayPosition == .first ? 0 : nookSettings.widgetsPadding,
            bottom: 0,
            trailing: arrayPosition == .last ? 0 : nookSettings.widgetsPadding)
        )
    }
}
