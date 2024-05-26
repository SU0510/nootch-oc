//
//  MediaPlayerWidgetView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI
import MusicKit

struct MediaPlayerWidgetView: View {
    var ns: Namespace.ID
    var body: some View {
        VStack {
            if let app = MediaPlayer.shared.app, app.isAppRunning {
                MediaPlayerView(track: app.track, appIcon: app.meta.icon, ns: ns)
            } else {
                NoMediaAppsView()
            }
        }
        .frame(minWidth: 225, maxWidth: 225, maxHeight: .infinity, alignment: .leading)
    }
}
