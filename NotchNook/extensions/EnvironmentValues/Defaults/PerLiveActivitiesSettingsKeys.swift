//
//  PerLiveActivitiesSettingsKeys.swift
//  NotchNook
//
//  Created by Igor Marcossi on 09/07/24.
//

import SwiftUI

// MARK: - MediaLiveActivitySettings

private struct MediaLiveActivitySettingsKey: EnvironmentKey {
    static var defaultValue = MediaLiveActivitySettings()
}

extension EnvironmentValues {
    var mediaLiveActivitySettings: MediaLiveActivitySettings {
        get { self[MediaLiveActivitySettingsKey.self] }
        set { self[MediaLiveActivitySettingsKey.self] = newValue }
    }
}

// MARK: - CalendarLiveActivitySettings

private struct CalendarLiveActivitySettingsKey: EnvironmentKey {
    static var defaultValue = CalendarLiveActivitySettings()
}

extension EnvironmentValues {
    var calendarLiveActivitySettings: CalendarLiveActivitySettings {
        get { self[CalendarLiveActivitySettingsKey.self] }
        set { self[CalendarLiveActivitySettingsKey.self] = newValue }
    }
}
