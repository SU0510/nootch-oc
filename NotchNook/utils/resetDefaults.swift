//
//  resetDefaults.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI
import Defaults

func resetDefaults() {
    Defaults[.intro] = true
    Defaults[.mediaLiveActivitySettings] = MediaLiveActivitySettings()
    Defaults[.liveActivitiesSettings] = LiveActivitiesSettings()
    Defaults[.generalSettings] = GeneralSettings()
    Defaults[.mediaWidgetSettings] = MediaWidgetSettings()
    Defaults[.shortcutsWidgetSettings] = ShortcutsWidgetSettings()
    Defaults[.mirrorWidgetSettings] = MirrorWidgetSettings()
    Defaults[.gestureControlSettings] = GestureControlSettings()
    Defaults[.nookSettings] = NookSettings()
    Defaults[.traySettings] = TraySettings()
    Defaults[.dropAreaSettings] = DropAreaSettings()
}
