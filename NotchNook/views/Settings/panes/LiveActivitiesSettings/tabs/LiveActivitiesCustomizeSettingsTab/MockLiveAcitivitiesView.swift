//
//  MockLiveAcitivitiesView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI
import Defaults

struct MockLiveAcitivitiesView: View {

    var activity: LiveActivity

    @Environment(\.notchSize) private var notchSize

    // The Settings window doesn't go through RootView, so it never injects the
    // per-setting environment values that MockTopBar (and its effects) read —
    // they'd fall back to static EnvironmentKey defaults and the preview wouldn't
    // react to any adjustment. Read them live here and inject them below.
    @Default(.liveActivitiesSettings) private var liveActivitiesSettings
    @Default(.mediaLiveActivitySettings) private var mediaLiveActivitySettings
    @Default(.calendarLiveActivitySettings) private var calendarLiveActivitySettings
    @Default(.gestureControlSettings) private var gestureControlSettings
    @Default(.nookSettings) private var nookSettings
    @Default(.traySettings) private var traySettings

    var body: some View {
        ZStack(alignment: .top) {
            MockTopBar(activity: activity)
                .background {
                    NotchShape(notchSize: notchSize).offset(y: -1).fill(.black)
                }
                .clipShape(NotchShape(notchSize: notchSize).offset(y: -1))
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .top)
        .background { ActualSizeCurrentWallpaperView() }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .environment(\.liveActivitiesSettings, liveActivitiesSettings)
        .environment(\.mediaLiveActivitySettings, mediaLiveActivitySettings)
        .environment(\.calendarLiveActivitySettings, calendarLiveActivitySettings)
        .environment(\.gestureControlSettings, gestureControlSettings)
        .environment(\.nookSettings, nookSettings)
        .environment(\.traySettings, traySettings)
    }
}
