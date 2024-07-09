//
//  GeneralSettingsKeys.swift
//  NotchNook
//
//  Created by Igor Marcossi on 09/07/24.
//

import SwiftUI

// MARK: - GeneralSettings

private struct GeneralSettingsKey: EnvironmentKey {
    static var defaultValue = GeneralSettings()
}

extension EnvironmentValues {
    var generalSettings: GeneralSettings {
        get { self[GeneralSettingsKey.self] }
        set { self[GeneralSettingsKey.self] = newValue }
    }
}


// MARK: - GestureControlSettings

private struct GestureControlSettingsKey: EnvironmentKey {
    static var defaultValue = GestureControlSettings()
}

extension EnvironmentValues {
    var gestureControlSettings: GestureControlSettings {
        get { self[GestureControlSettingsKey.self] }
        set { self[GestureControlSettingsKey.self] = newValue }
    }
}


// MARK: - LiveActivitiesSettings

private struct LiveActivitiesSettingsKey: EnvironmentKey {
    static var defaultValue = LiveActivitiesSettings()
}

extension EnvironmentValues {
    var liveActivitiesSettings: LiveActivitiesSettings {
        get { self[LiveActivitiesSettingsKey.self] }
        set { self[LiveActivitiesSettingsKey.self] = newValue }
    }
}


// MARK: - NookSettings

private struct NookSettingsKey: EnvironmentKey {
    static var defaultValue = NookSettings()
}

extension EnvironmentValues {
    var nookSettings: NookSettings {
        get { self[NookSettingsKey.self] }
        set { self[NookSettingsKey.self] = newValue }
    }
}


// MARK: - TraySettings

private struct TraySettingsKey: EnvironmentKey {
    static var defaultValue = TraySettings()
}

extension EnvironmentValues {
    var traySettings: TraySettings {
        get { self[TraySettingsKey.self] }
        set { self[TraySettingsKey.self] = newValue }
    }
}


// MARK: - DropAreaSettings

private struct DropAreaSettingsKey: EnvironmentKey {
    static var defaultValue = DropAreaSettings()
}

extension EnvironmentValues {
    var dropAreaSettings: DropAreaSettings {
        get { self[DropAreaSettingsKey.self] }
        set { self[DropAreaSettingsKey.self] = newValue }
    }
}

